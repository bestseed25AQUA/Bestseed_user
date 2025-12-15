import 'package:flutter/material.dart';

class AppSize {
  static bool _initialized = false;
  static late final double height;
  static late final double width;

  static void init(BuildContext context) {
    if (_initialized) return;

    final size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    _initialized = true;
  }
}
