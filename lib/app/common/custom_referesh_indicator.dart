import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:seedsuser/app/common/app_color.dart';

class CustomRefereshIndicator extends StatelessWidget {
  const CustomRefereshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });
  final Widget child;
  final Future<void> Function() onRefresh;
  @override
  Widget build(context) {
    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: AppColors.primary,
      strokeWidth: 3,
      displacement: 60,
      elevation: 6,
      onRefresh:onRefresh,
      child: child,
    );
  }
}
