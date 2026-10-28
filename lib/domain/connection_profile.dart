import '../core/json.dart';
import 'obs_models.dart';

/// A saved OBS computer. The password lives in secure storage, keyed by [id].
class ConnectionProfile {
  const ConnectionProfile({
    required this.id,
    required this.name,
    required this.host,
    this.port = defaultObsPort,
  });

  factory ConnectionProfile.fromJson(JsonMap json) => ConnectionProfile(
    id: json.str('id'),
    name: json.str('name'),
    host: json.str('host'),
    port: json.integer('port', defaultObsPort),
  );

  final String id;
  final String name;
  final String host;
  final int port;

  JsonMap toJson() => {'id': id, 'name': name, 'host': host, 'port': port};

  ConnectionProfile copyWith({String? name, String? host, int? port}) =>
      ConnectionProfile(
        id: id,
        name: name ?? this.name,
        host: host ?? this.host,
        port: port ?? this.port,
      );

  ObsConnectionConfig toConfig(String password) =>
      ObsConnectionConfig(host: host, port: port, password: password);
}

/// Validates what the user typed in the address field. Returns null when OK.
enum HostValidation { empty, hasScheme, hasPort, invalid }

HostValidation? validateHost(String raw) {
  final host = raw.trim();
  if (host.isEmpty) return HostValidation.empty;
  if (host.contains('://')) return HostValidation.hasScheme;
  if (RegExp(r'^[\d.]+:\d+$').hasMatch(host)) return HostValidation.hasPort;
  final ipv4 = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$');
  final match = ipv4.firstMatch(host);
  if (match != null) {
    final ok = List.generate(
      4,
      (i) => int.parse(match.group(i + 1)!),
    ).every((part) => part <= 255);
    return ok ? null : HostValidation.invalid;
  }
  if (RegExp(r'^[\d.]+$').hasMatch(host)) return HostValidation.invalid;
  final hostname = RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9\-.]*[a-zA-Z0-9])?$');
  return hostname.hasMatch(host) ? null : HostValidation.invalid;
}
