typedef JsonMap = Map<String, dynamic>;

String readString(JsonMap map, String key, {String fallback = ''}) {
  final value = map[key];
  return value == null ? fallback : value.toString();
}

String? readNullableString(JsonMap map, String key) {
  final value = map[key];
  return value?.toString();
}

bool readBool(JsonMap map, String key, {bool fallback = false}) {
  final value = map[key];
  if (value is bool) return value;
  return fallback;
}

int readInt(JsonMap map, String key, {int fallback = 0}) {
  final value = map[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double readDouble(JsonMap map, String key, {double fallback = 0}) {
  final value = map[key];
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

num readNum(JsonMap map, String key, {num fallback = 0}) {
  final value = map[key];
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime readDateTime(JsonMap map, String key, {DateTime? fallback}) {
  final value = map[key];
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '') ??
      fallback ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

List<String> readStringList(JsonMap map, String key) {
  final value = map[key];
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}

JsonMap asJsonMap(Object? value) => JsonMap.from(value as Map);
