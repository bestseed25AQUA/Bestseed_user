import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';

class VoiceMicButton extends StatelessWidget {
  final VoidCallback onStart;

  const VoiceMicButton({
    super.key,
    required this.onStart,
    this.padding,
    this.iconSize,
  });
  final EdgeInsetsGeometry? padding;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: padding,
      // onLongPress: onStart,
      // onLongPressUp: onStop,
      onPressed: onStart,
      icon: Icon(Icons.mic, color: Colors.blue, size: iconSize ?? 24),
    );
  }
}
