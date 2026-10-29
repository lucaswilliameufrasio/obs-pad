import 'dart:io';

import 'package:path/path.dart' as p;

/// An IPv4 address of this computer the phone can use.
class LanAddress {
  const LanAddress(this.ip, {this.vpn = false});

  final String ip;

  /// Tailscale/NetBird (100.64.0.0/10): reachable from outside home.
  final bool vpn;
}

/// What the app needs from the operating system (faked in tests).
abstract interface class DesktopSystem {
  String get computerName;
  bool get isWindows;

  /// Where sounds sent by the phone are saved.
  Directory get soundsDir;

  Future<bool> isObsRunning();
  Future<List<LanAddress>> lanAddresses();
  Future<void> openFolder(Directory dir);

  /// Asks Windows (with the admin prompt) to allow OBS (4455) and this app
  /// (4457) on private networks. Returns false if the user said no.
  Future<bool> allowThroughFirewall({required int obsPort});
}

class RealDesktopSystem implements DesktopSystem {
  @override
  String get computerName => Platform.localHostname;

  @override
  bool get isWindows => Platform.isWindows;

  @override
  Directory get soundsDir {
    final env = Platform.environment;
    final home = env['USERPROFILE'] ?? env['HOME'] ?? Directory.current.path;
    return Directory(p.join(home, 'OBS Pad', 'Sons'));
  }

  @override
  Future<bool> isObsRunning() async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run('tasklist', [
          '/FI',
          'IMAGENAME eq obs64.exe',
          '/NH',
        ]);
        return '${result.stdout}'.toLowerCase().contains('obs64.exe');
      }
      // Linux: "obs"; macOS: "OBS".
      final result = await Process.run('pgrep', ['-xi', 'obs']);
      return result.exitCode == 0;
    } on ProcessException {
      return false;
    }
  }

  @override
  Future<List<LanAddress>> lanAddresses() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );
    final addresses = <LanAddress>[];
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        if (address.isLoopback || address.isLinkLocal) continue;
        addresses.add(LanAddress(address.address, vpn: isVpnAddress(address)));
      }
    }
    // Home network first, VPN last, containers/virtual machines dropped
    // when there is anything better.
    addresses.sort((a, b) => _rank(a).compareTo(_rank(b)));
    return addresses;
  }

  static int _rank(LanAddress a) {
    if (a.vpn) return 2;
    if (a.ip.startsWith('192.168.')) return 0;
    if (a.ip.startsWith('10.')) return 1;
    return 1;
  }

  static bool isVpnAddress(InternetAddress address) {
    final bytes = address.rawAddress;
    return bytes.length == 4 && bytes[0] == 100 && (bytes[1] & 0xC0) == 64;
  }

  @override
  Future<void> openFolder(Directory dir) async {
    await dir.create(recursive: true);
    final command = Platform.isWindows
        ? 'explorer'
        : Platform.isMacOS
        ? 'open'
        : 'xdg-open';
    await Process.start(command, [dir.path], mode: ProcessStartMode.detached);
  }

  @override
  Future<bool> allowThroughFirewall({required int obsPort}) async {
    if (!Platform.isWindows) return true;
    // One elevated PowerShell running netsh; private networks only.
    final rules = [
      'netsh advfirewall firewall add rule name="OBS Pad - OBS" dir=in '
          'action=allow protocol=TCP localport=$obsPort profile=private',
      'netsh advfirewall firewall add rule name="OBS Pad Desktop" dir=in '
          'action=allow protocol=TCP localport=4457 profile=private',
      'netsh advfirewall firewall add rule name="OBS Pad Desktop (busca)" '
          'dir=in action=allow protocol=UDP localport=4457 profile=private',
    ].join('; ');
    final script =
        'Start-Process powershell -Verb RunAs -Wait -WindowStyle Hidden '
        "-ArgumentList '-NoProfile','-Command','${rules.replaceAll("'", "''")}'";
    try {
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        script,
      ]);
      return result.exitCode == 0;
    } on ProcessException {
      return false;
    }
  }
}
