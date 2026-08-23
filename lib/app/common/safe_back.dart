import 'package:get/get.dart';

/// Pops the current route safely, working around two related GetX 4.7.x bugs
/// caused by a snackbar that was enqueued but never fully mounted.
///
/// `SnackbarController._controller` is `late final` and is only created once
/// the snackbar actually mounts, but `Get.isSnackbarOpen` turns true as soon as
/// the job is *queued*. Closing such a snackbar throws
/// `LateInitializationError: Field '_controller' has not been initialized`:
///
///  1. The throw happens inside `closeCurrentSnackbar()`, which is `async`, so
///     it surfaces as an *unhandled* async error that a plain synchronous
///     try/catch cannot intercept. Hence the `catchError` below.
///
///  2. `Get.back()` short-circuits — `if (isSnackbarOpen) { ...; return; }` —
///     so it closes the snackbar and returns **without popping the route**.
///     Worse, the failed close leaves the queue dirty, so `isSnackbarOpen`
///     stays true and every later `Get.back()` silently refuses to pop. We
///     therefore pop through the navigator directly instead of `Get.back()`.
///
/// Pop semantics mirror `Get.back()`: with [canPop] true the route is popped
/// only when the navigator reports it can pop. Drop-in replacement for
/// `Get.back()`.
void safeBack<T>({T? result, bool canPop = true}) {
  if (Get.isSnackbarOpen) {
    try {
      // ignore: body_might_complete_normally_catch_error
      Get.closeCurrentSnackbar().catchError((_) {});
    } catch (_) {
      // Swallow a synchronous failure from a half-mounted snackbar.
    }
  }

  final navigator = Get.key.currentState;
  if (navigator == null) return;

  if (canPop && !navigator.canPop()) return;
  navigator.pop<T>(result);
}
