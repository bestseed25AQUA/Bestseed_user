/// One definition of how dates look, and how they travel.
///
/// The farmer sees `dd-MM-yyyy` — 02-09-2026. The server takes `yyyy-MM-dd`.
/// Keeping both in one place is the point: a screen that formats its own dates
/// eventually formats them differently from the screen next to it, and a field
/// whose controller holds the display form will happily post "02-09-2026" to an
/// API that reads it as a different day, or rejects it outright.
///
/// So: [displayDate] to show, [isoDate] to send, [parseDisplayDate] to read
/// back whatever a field currently holds.
library;

/// `dd-MM-yyyy`, for anything the farmer reads.
String displayDate(DateTime date) =>
    "${date.day.toString().padLeft(2, '0')}-"
    "${date.month.toString().padLeft(2, '0')}-"
    "${date.year}";

/// The same, from an ISO string the API sent. Returns [fallback] when there is
/// no usable date — a dash reads better than an empty gap in a table.
String displayDateFrom(String? isoOrDisplay, {String fallback = '-'}) {
  final parsed = parseDisplayDate(isoOrDisplay);
  return parsed == null ? fallback : displayDate(parsed);
}

/// Parse either form back to a DateTime.
///
/// Takes the display form the text fields hold, and ISO too, because values
/// arrive from the API in ISO before the farmer has touched anything.
DateTime? parseDisplayDate(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;

  final parts = text.split('-');

  // dd-MM-yyyy. The two-digit first part is what separates it from ISO, whose
  // first part is the four-digit year.
  if (parts.length == 3 && parts.first.length == 2) {
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day != null && month != null && year != null) {
      return DateTime(year, month, day);
    }
  }

  return DateTime.tryParse(text);
}

/// The `yyyy-MM-dd` the server expects, from whatever a field currently holds.
/// Empty when there is no usable date, so a caller can skip sending it.
String isoDate(String? value) {
  final parsed = parseDisplayDate(value);
  if (parsed == null) return '';

  return "${parsed.year.toString().padLeft(4, '0')}-"
      "${parsed.month.toString().padLeft(2, '0')}-"
      "${parsed.day.toString().padLeft(2, '0')}";
}
