import 'package:flutter/material.dart';

class AppSize {
  static bool _initialized = false;
  static double height = 0;
  static double width = 0;

  static void init(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Only accept valid sizes (non-zero) to avoid locking in 0 values
    if (size.height > 0 && size.width > 0) {
      height = size.height;
      width = size.width;
      _initialized = true;
    }
  }
}
