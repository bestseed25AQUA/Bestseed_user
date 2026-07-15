import 'package:get/get.dart';

/// Pops the current route safely, working around a GetX 4.7.x bug where
/// `Get.back()` always invokes `closeCurrentSnackbar()` and throws
/// `LateInitializationError: Field '_controller' has not been initialized`
/// when a snackbar was enqueued but never fully mounted.
///
/// Wraps the snackbar close in try/catch, then performs the navigation pop.
/// Drop-in replacement for `Get.back()`.
void safeBack<T>({T? result, bool canPop = true}) {
  try {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
  } catch (_) {
    // Swallow the LateInitializationError from a half-mounted snackbar.
  }
  try {
    Get.back<T>(result: result, canPop: canPop);
  } catch (_) {
    // As a last resort, ignore — the route is likely already being popped.
  }
}
