/// Keys whose values must never appear in a log line, even in debug builds.
/// Matched case-insensitively against map keys at any nesting depth.
const Set<String> sensitiveLogKeys = <String>{
  'address',
  'deliveryaddress',
  'street',
  'house',
  'apartment',
  'entrance',
  'floor',
  'doorcode',
  'comment',
  'latitude',
  'longitude',
  'lat',
  'lng',
  'lon',
  'phone',
  'phonenumber',
  'fullname',
  'firstname',
  'lastname',
  'email',
  'paymenturl',
  'accesstoken',
  'refreshtoken',
  'token',
  'authorization',
};

const String redactedLogValue = '<redacted>';

/// Returns a deep copy of [value] with every [sensitiveLogKeys] entry replaced
/// by [redactedLogValue]. Lists and maps are walked recursively; other values
/// are returned as-is.
Object? redactSensitiveLogFields(Object? value) {
  if (value is Map) {
    return <String, Object?>{
      for (final entry in value.entries)
        entry.key.toString(): _isSensitiveKey(entry.key.toString())
            ? redactedLogValue
            : redactSensitiveLogFields(entry.value),
    };
  }
  if (value is List) {
    return value.map(redactSensitiveLogFields).toList(growable: false);
  }
  return value;
}

bool _isSensitiveKey(String key) {
  return sensitiveLogKeys.contains(key.replaceAll('_', '').toLowerCase());
}
