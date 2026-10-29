/// Connection details read from a QR code.
///
/// Two formats:
/// - `obsws://192.168.0.15:4455/password` — the QR in OBS itself
///   (Tools › WebSocket Server Settings › Show Connect Info);
/// - `obspad://connect?host=…&port=…&password=…&name=…` — the QR of
///   OBS Pad Desktop, which also names the computer.
class ConnectionLink {
  const ConnectionLink({
    required this.host,
    required this.port,
    required this.password,
    this.name,
  });

  final String host;
  final int port;
  final String password;

  /// Computer name, when the QR has it.
  final String? name;

  static ConnectionLink? tryParse(String text) {
    final uri = Uri.tryParse(text.trim());
    if (uri == null || uri.host.isEmpty && uri.scheme != 'obspad') return null;
    switch (uri.scheme) {
      case 'obsws':
        final password = uri.pathSegments.isEmpty
            ? ''
            : Uri.decodeComponent(uri.pathSegments.join('/'));
        return ConnectionLink(
          host: uri.host,
          port: uri.hasPort ? uri.port : 4455,
          password: password,
        );
      case 'obspad':
        final q = uri.queryParameters;
        final host = q['host'] ?? '';
        if (host.isEmpty) return null;
        return ConnectionLink(
          host: host,
          port: int.tryParse(q['port'] ?? '') ?? 4455,
          password: q['password'] ?? '',
          name: (q['name'] ?? '').isEmpty ? null : q['name'],
        );
      default:
        return null;
    }
  }

  String toObsPadUri() => Uri(
    scheme: 'obspad',
    host: 'connect',
    queryParameters: {
      'host': host,
      'port': '$port',
      'password': password,
      if (name != null) 'name': name,
    },
  ).toString();
}
