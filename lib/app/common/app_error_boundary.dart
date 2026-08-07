import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Makes Flutter's silent release-mode failure visible.
///
/// When any widget throws inside `build()`, Flutter replaces it with an
/// [ErrorWidget]. The default one is a `RenderErrorBox`, which paints
/// `RenderErrorBox.backgroundColor` — dark red in debug, but
/// `Color(0xF0C0C0C0)` (plain light grey) in release, because that colour is
/// chosen behind an `assert`. So on a release build a broken widget becomes a
/// featureless grey rectangle exactly filling its slot, with nothing written
/// anywhere. That is the "blank grey screen" users report: the app did not
/// hang and the network was fine — one widget threw and Flutter painted grey
/// over it.
///
/// [install] replaces that grey with a labelled panel and records every
/// failure, so the next occurrence is screenshot-able and reportable instead
/// of anonymous.
class AppErrorBoundary {
  AppErrorBoundary._();

  /// The grey Flutter paints in release when a build() throws.
  /// Kept here so tests can assert against the exact value.
  static const Color releaseErrorBoxColor = Color(0xF0C0C0C0);

  /// Most recent UI failures, newest last. Capped so it can never grow
  /// without bound in a long-running session.
  static final List<FlutterErrorDetails> recorded = <FlutterErrorDetails>[];
  static const int _maxRecorded = 50;

  static bool _installed = false;
  static FlutterExceptionHandler? _previousOnError;
  static ErrorWidgetBuilder? _previousBuilder;

  /// Optional sink — wire to Crashlytics/Sentry when one is added.
  static void Function(FlutterErrorDetails details)? reporter;

  static void install({void Function(FlutterErrorDetails details)? report}) {
    if (_installed) return;
    _installed = true;
    reporter = report;

    _previousOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      _record(details);
      _previousOnError?.call(details);
    };

    _previousBuilder = ErrorWidget.builder;
    ErrorWidget.builder = (FlutterErrorDetails details) {
      _record(details);
      return AppErrorPanel(details: details);
    };
  }

  static void _record(FlutterErrorDetails details) {
    recorded.add(details);
    if (recorded.length > _maxRecorded) recorded.removeAt(0);
    debugPrint('🔴 [UI-ERROR] ${details.exceptionAsString()}');
    // A throwing reporter must never take the app down with it — this code
    // already runs while something else is broken.
    try {
      reporter?.call(details);
    } catch (_) {}
  }

  @visibleForTesting
  static void resetForTest() {
    if (!_installed) return;
    FlutterError.onError = _previousOnError;
    if (_previousBuilder != null) ErrorWidget.builder = _previousBuilder!;
    _installed = false;
    recorded.clear();
    reporter = null;
  }
}

/// Shown in place of a widget whose build() threw.
///
/// Deliberately built from the most primitive widgets available and supplies
/// its own [Directionality]: it gets inserted wherever the failure happened,
/// which may be outside any MaterialApp/Theme scope, and it must not be
/// capable of throwing itself.
class AppErrorPanel extends StatelessWidget {
  const AppErrorPanel({super.key, required this.details});

  final FlutterErrorDetails details;

  static const TextStyle _title = TextStyle(
    color: Color(0xFFB3261E),
    fontSize: 14,
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.none,
  );

  static const TextStyle _body = TextStyle(
    color: Color(0xFF5F6368),
    fontSize: 11,
    decoration: TextDecoration.none,
  );

  @override
  Widget build(BuildContext context) {
    // Keep it short: this string can be rendered in a very small slot.
    var message = details.exceptionAsString();
    if (message.length > 240) message = '${message.substring(0, 240)}…';

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: const Color(0xFFFFF4F4),
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 30, color: Color(0xFFB3261E)),
            const SizedBox(height: 8),
            const Text(
              "This section couldn't be displayed",
              style: _title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(message, style: _body, textAlign: TextAlign.center, maxLines: 6),
          ],
        ),
      ),
    );
  }
}
