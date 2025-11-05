import 'package:flutter/material.dart';

class CustomNetworkImage extends StatelessWidget {
  const CustomNetworkImage({
    super.key,
    required this.imageUrl,
      this.height,
      this.width, this.fit,
  });
  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit? fit;
  @override
  Widget build(context) {
    print(imageUrl);
    return Image.network(
      imageUrl,fit: fit,
      height: height,
      width: width,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        // return Image.asset('assets/images/default_image.png');
         return Container(color: Colors.grey.withOpacity(.3),);
      },
      errorBuilder: (context, error, stackTrace) {
        // return Image.asset('assets/images/default_image.png');
         return Container(color: Colors.grey.withOpacity(.3),);
      },
    );
  }
}
