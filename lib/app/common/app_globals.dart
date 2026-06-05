import 'package:flutter/material.dart';

/// App-wide navigator key.
///
/// Used by `GetMaterialApp(navigatorKey: navigatorKey)` and by code that needs
/// a `BuildContext` outside the widget tree (e.g. showing a dialog/snackbar
/// after an async gap) via `navigatorKey.currentContext`.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
