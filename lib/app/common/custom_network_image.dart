import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

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

  Widget _shimmer() => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(color: Colors.white),
      );

  @override
  Widget build(context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      height: height,
      width: width,
      fadeInDuration: const Duration(milliseconds: 200),
      // Shimmer rather than a flat grey box or a stock image: it reads as
      // "loading / nothing here" without pretending to be the real picture.
      placeholder: (context, url) => _shimmer(),
      errorWidget: (context, url, error) => _shimmer(),
    );
  }
}
