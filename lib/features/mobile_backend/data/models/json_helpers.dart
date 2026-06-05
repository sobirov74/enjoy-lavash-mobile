typedef JsonMap = Map<String, dynamic>;

JsonMap asJsonMap(Object? value) {
  if (value is JsonMap) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return const <String, dynamic>{};
}

List<JsonMap> asJsonMapList(Object? value) {
  if (value is! List) return const <JsonMap>[];
  return value.map(asJsonMap).where((map) => map.isNotEmpty).toList();
}

List<Object?> asObjectList(Object? value) {
  if (value is List) return value;
  return const <Object?>[];
}

String? stringOrNull(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

String readString(JsonMap json, List<String> keys, {String fallback = ''}) {
  return stringOrNull(_firstValue(json, keys)) ?? fallback;
}

int readInt(JsonMap json, List<String> keys, {int fallback = 0}) {
  final value = _firstValue(json, keys);
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double readDouble(JsonMap json, List<String> keys, {double fallback = 0}) {
  final value = _firstValue(json, keys);
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

bool readBool(JsonMap json, List<String> keys, {bool fallback = false}) {
  final value = _firstValue(json, keys);
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
  return fallback;
}

DateTime? readDateTime(JsonMap json, List<String> keys) {
  final value = _firstValue(json, keys);
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

String localizedText(Object? value, String language, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is String) return value;
  if (value is Map) {
    final map = asJsonMap(value);
    final preferred = stringOrNull(map[language]);
    if (preferred != null && preferred.isNotEmpty) return preferred;

    for (final key in const ['ru', 'uz', 'en', 'value', 'text', 'name']) {
      final candidate = stringOrNull(map[key]);
      if (candidate != null && candidate.isNotEmpty) return candidate;
    }

    for (final entry in map.values) {
      final candidate = stringOrNull(entry);
      if (candidate != null && candidate.isNotEmpty) return candidate;
    }
  }
  return stringOrNull(value) ?? fallback;
}

Map<String, Object?> withoutNulls(Map<String, Object?> source) {
  return Map<String, Object?>.from(source)
    ..removeWhere((_, value) => value == null);
}

Object? _firstValue(JsonMap json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key) && json[key] != null) {
      return json[key];
    }
  }
  return null;
}
