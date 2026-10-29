// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'OBS Pad Desktop';

  @override
  String get appSubtitle =>
      'Keep this app open while you use OBS Pad on your phone. It finds this computer for the phone and receives the sounds you send.';

  @override
  String get obsSection => 'OBS on this computer';

  @override
  String get obsNotFound =>
      'OBS settings not found. Open OBS once (version 28 or newer), close it and come back here.';

  @override
  String get obsRunning => 'OBS is open';

  @override
  String get obsClosed => 'OBS is closed';

  @override
  String phoneControlOn(int port) {
    return 'Phone control is on (port $port, with password)';
  }

  @override
  String get phoneControlOff => 'Phone control is off';

  @override
  String get phoneControlNoPassword =>
      'Phone control is on, but without a password';

  @override
  String get enableButton => 'Turn on phone control';

  @override
  String get enableNeedsClosedObs =>
      'Close OBS first: it undoes this change when it closes. Then press the button.';

  @override
  String get enableExplain =>
      'This turns on the OBS WebSocket server with a password, the same as doing it in OBS under Tools › WebSocket Server Settings.';

  @override
  String get enableDone => 'Done! Open OBS again and connect the phone below.';

  @override
  String get enableFailed =>
      'Could not change the OBS settings. Do it in OBS: Tools › WebSocket Server Settings › Enable, with a password.';

  @override
  String get connectSection => 'Connect the phone';

  @override
  String get connectHowTo =>
      'In OBS Pad on the phone, tap \"Read QR code\" and point the camera here. Or tap \"Find on network\".';

  @override
  String get showQr => 'Show QR code';

  @override
  String get hideQr => 'Hide QR code';

  @override
  String get qrWarning =>
      'The QR code contains the OBS password. Only show it to people you trust.';

  @override
  String get addressLabel => 'Computer IP';

  @override
  String addressVpn(String ip) {
    return '$ip (VPN, works away from home)';
  }

  @override
  String get noAddress =>
      'No network found. Connect this computer to the Wi-Fi or cable.';

  @override
  String get portLabel => 'Port';

  @override
  String get passwordLabel => 'Password';

  @override
  String get showPassword => 'Show';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get soundsSection => 'Sounds';

  @override
  String get soundsFolder => 'Sounds sent from the phone are saved in:';

  @override
  String soundsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sounds',
      one: '1 sound',
      zero: 'No sounds yet',
    );
    return '$_temp0';
  }

  @override
  String get openFolder => 'Open folder';

  @override
  String get firewallSection => 'Windows Firewall';

  @override
  String get firewallExplain =>
      'If the phone cannot find or connect to this computer, allow OBS and OBS Pad on private networks. Windows will ask for permission.';

  @override
  String get firewallButton => 'Allow on the firewall';

  @override
  String get firewallDone =>
      'Done. Also check that the Wi-Fi is set as a Private network.';

  @override
  String get firewallFailed =>
      'It was not allowed. Try again and answer \"Yes\" on the Windows prompt.';

  @override
  String get serverFailed =>
      'Another program is using port 4457 (maybe OBS Pad Desktop is already open). The phone will not find this computer or send sounds until you close it.';

  @override
  String get activitySection => 'What the phone did';

  @override
  String get activityEmpty => 'Nothing yet.';

  @override
  String activityDiscovered(String ip) {
    return 'A phone found this computer ($ip)';
  }

  @override
  String get activityListed => 'The phone opened the sounds list';

  @override
  String activityUploaded(String name) {
    return 'Received \"$name\"';
  }

  @override
  String activityRejected(String ip) {
    return 'Refused a request from $ip: the OBS password on the phone is different';
  }

  @override
  String activityRejectedOther(String ip, String reason) {
    return 'Refused a request from $ip ($reason)';
  }
}
