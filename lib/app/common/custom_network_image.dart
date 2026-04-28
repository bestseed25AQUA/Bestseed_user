import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CustomNetworkImage extends StatelessWidget {
  const CustomNetworkImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit,
  });
  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit? fit;

  @override
  Widget build(context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      height: height,
      width: width,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (context, url) =>
          Container(color: Colors.grey.withValues(alpha: .3)),
      errorWidget: (context, url, error) =>
          Container(color: Colors.grey.withValues(alpha: .3)),
    );
  }
}
