import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';

class VoiceListeningDialog extends StatelessWidget {
  final String text;

  const VoiceListeningDialog({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        width: 260,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Voice assistance",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 25),

            /// Blue Circle Mic Animation Style
            Container(
              height: 110,
              width: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue.shade100, Colors.blue.shade300],
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(15),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 45),
              ),
            ),

            const SizedBox(height: 25),

            /// Recognized Text
            Text(
              text.isEmpty ? "Listening..." : text,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
