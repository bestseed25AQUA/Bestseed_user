import 'package:flutter/material.dart';

class CustomBestSeedBackground extends StatelessWidget {
  const CustomBestSeedBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset(
          'assets/images/bottom_image.png',
          width: MediaQuery.of(context).size.width * .35,
          height: 170,
          fit: BoxFit.fitHeight,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 20, right: 12),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * .45,
            height: 100,
            child: FittedBox(
              fit: BoxFit.fitHeight,
              alignment: Alignment.centerRight,
              child: Text(
                'BEST\nSEED',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: const Color(0xFFD4D2D2),
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  letterSpacing: -1,
                  fontSize: 60,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
