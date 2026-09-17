/// Tolerant coercion for JSON produced by the language model.
///
/// The extraction arrives from an LLM, which does not always honour the
/// schema: it can return `"fever, cough"` where a list is expected, `"3"` for
/// a number, or omit a medicine's name. The generated json_serializable
/// decoders cast strictly, so any one of those threw and the WHOLE recorded
/// consultation was lost. These helpers reshape the map into what the
/// decoders expect first, keeping every value the doctor dictated rather than
/// discarding it.
library;

/// A string field: strings are trimmed, other scalars become their text,
/// and null / collections become [fallback].
String coerceString(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return fallback;
}

/// A nullable string field.
String? coerceOptionalString(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return null;
}

/// A list-of-strings field. A single string is split into items on newlines,
/// semicolons or commas, so "fever, cough" is kept as two symptoms rather
/// than lost.
List<String> coerceStringList(Object? value) {
  if (value == null) return const [];
  if (value is List) {
    return [
      for (final item in value)
        if (coerceOptionalString(item) case final text?)
          if (text.trim().isNotEmpty) text.trim(),
    ];
  }
  if (value is String) {
    return value
        .split(RegExp(r'[\n;,]'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }
  if (value is num || value is bool) return [value.toString()];
  return const [];
}

/// An optional whole number: numbers are truncated, numeric strings such as
/// "3" or "3 days" are parsed, anything else is null.
int? coerceOptionalInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final match = RegExp(r'-?\d+').firstMatch(value);
    return match == null ? null : int.tryParse(match.group(0)!);
  }
  return null;
}

/// A boolean flag, accepting the forms a model tends to emit.
bool coerceBool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.trim().toLowerCase();
    if (v == 'true' || v == 'yes' || v == '1') return true;
    if (v == 'false' || v == 'no' || v == '0') return false;
  }
  return fallback;
}

/// A map with string keys, or null when [value] is not a map.
Map<String, dynamic>? coerceMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return {for (final e in value.entries) e.key.toString(): e.value};
  }
  return null;
}
