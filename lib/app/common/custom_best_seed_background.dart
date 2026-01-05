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
          padding: const EdgeInsets.only(top: 20),
          child: Image.asset(
            'assets/images/best_seed_text.png',
            width: MediaQuery.of(context).size.width * .45,
            height: 100,
            fit: BoxFit.fitHeight,
            errorBuilder: (context, error, stackTrace) {
              print(error.toString());
              return SizedBox();
            },
          ),
        ),
      ],
    );
  }
}
