import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// File-based logger for the customer-side vehicle tracking screen.
///
/// Writes every poll result to a daily file so you can review exactly
/// what the user app received during a locked-phone journey.
///
/// File location (Android):
///   /sdcard/Android/data/<pkg>/files/user_tracking_YYYY-MM-DD.log
///
/// Pull after a journey:
///   adb pull /sdcard/Android/data/<pkg>/files/user_tracking_YYYY-MM-DD.log
///
/// Usage:
///   await UserTrackingLog.init(bookingId);   // call once in initState
///   UserTrackingLog.log('POLL lat=… lng=…'); // call on every poll
class UserTrackingLog {
  static const String _tag = '[USER-TRACKING]';
  static File? _logFile;
  static String? _bookingId;

  /// Initialise for a specific booking. Creates or appends to the day's file.
  static Future<void> init(String bookingId) async {
    _bookingId = bookingId;
    try {
      final dir = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      _logFile = File('${dir.path}/user_tracking_$dateStr.log');
      await _logFile!.writeAsString(
        '\n=== Session started ${now.toIso8601String()} booking=$bookingId ===\n',
        mode: FileMode.append,
      );
      debugPrint('$_tag Log file → ${_logFile!.path}');
    } catch (e) {
      debugPrint('$_tag Failed to init log file: $e');
      _logFile = null;
    }
  }

  /// Log a message with a timestamp. Non-blocking.
  static void log(String message) {
    final now = DateTime.now();
    final ts = now.toIso8601String().substring(11, 23); // HH:mm:ss.SSS
    final line = '$ts | booking=$_bookingId | $message';
    debugPrint('$_tag $line');
    _logFile?.writeAsString('$line\n', mode: FileMode.append)
        .catchError((dynamic _) => _logFile!);
  }

  static String? get logFilePath => _logFile?.path;
}
