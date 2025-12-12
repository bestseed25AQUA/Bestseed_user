import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CustomToast {
  static void show({
    required String message,
    ToastGravity gravity = ToastGravity.BOTTOM,
    Color backgroundColor = Colors.black87,
    Color textColor = Colors.white,
    int duration = 2,
  }) {
    Fluttertoast.cancel(); // prevent stacking
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: gravity,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: 14,
      timeInSecForIosWeb: duration,
    );
  }

  static void success(String message) {
    show(message: message, backgroundColor: Colors.green.shade600);
  }

  static void error(String message) {
    show(message: message, backgroundColor: Colors.red.shade600);
  }

  static void info(String message) {
    show(message: message, backgroundColor: Colors.blue.shade600);
  }
}
