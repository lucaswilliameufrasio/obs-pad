/// Small typed accessors so JSON parsing stays explicit under strict casts.
typedef JsonMap = Map<String, Object?>;

extension JsonRead on JsonMap {
  String str(String key, [String fallback = '']) {
    final value = this[key];
    return value is String ? value : fallback;
  }

  String? strOrNull(String key) {
    final value = this[key];
    return value is String ? value : null;
  }

  int integer(String key, [int fallback = 0]) {
    final value = this[key];
    return value is num ? value.toInt() : fallback;
  }

  int? intOrNull(String key) {
    final value = this[key];
    return value is num ? value.toInt() : null;
  }

  double number(String key, [double fallback = 0]) {
    final value = this[key];
    return value is num ? value.toDouble() : fallback;
  }

  bool boolean(String key, [bool fallback = false]) {
    final value = this[key];
    return value is bool ? value : fallback;
  }

  List<JsonMap> objects(String key) {
    final value = this[key];
    if (value is! List) return const [];
    return value.whereType<Map<String, Object?>>().toList(growable: false);
  }

  List<String> strings(String key) {
    final value = this[key];
    if (value is! List) return const [];
    return value.whereType<String>().toList(growable: false);
  }

  JsonMap? object(String key) {
    final value = this[key];
    return value is Map<String, Object?> ? value : null;
  }
}

/// `jsonDecode` returns `Map<String, dynamic>`; this normalises it.
JsonMap asJsonMap(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) {
    return value.map((key, v) => MapEntry(key.toString(), v as Object?));
  }
  return const {};
}
