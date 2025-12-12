import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';

class VoiceMicButton extends StatelessWidget {
  final VoidCallback onStart;

  const VoiceMicButton({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      // onLongPress: onStart,
      // onLongPressUp: onStop,
      onPressed: onStart,
      icon: Icon(Icons.mic, color: Colors.blue, size: 30),
    );
  }
}
