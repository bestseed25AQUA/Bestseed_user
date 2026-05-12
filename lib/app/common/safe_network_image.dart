import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SafeNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, Object)? onFinalError;
  final VoidCallback? onTap;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.onFinalError,
    this.onTap,
  });

  bool get _isVideo {
    final lower = imageUrl.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.webm');
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo) {
      return onFinalError?.call(context, imageUrl, Exception('video URL')) ??
          placeholder?.call(context, imageUrl) ??
          SizedBox(width: width, height: height);
    }

    if (imageUrl.isEmpty) {
      return onFinalError?.call(context, imageUrl, Exception('empty URL')) ??
          Container(
            width: width,
            height: height,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
          );
    }

    Widget child = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      httpHeaders: const {'Accept': 'image/*,*/*'},
      fadeInDuration: Duration.zero,
      placeholderFadeInDuration: const Duration(milliseconds: 0),
      placeholder: (ctx, url) =>
          placeholder?.call(ctx, url) ??
          _defaultShimmer(width, height),
      errorWidget: (ctx, url, error) {
        debugPrint('⚠️ SafeNetworkImage FAILED: $url → $error');
        return onFinalError?.call(ctx, url, error) ??
            Container(
              width: width,
              height: height,
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
            );
      },
    );

    if (onTap != null) {
      child = GestureDetector(onTap: onTap, child: child);
    }
    return child;
  }

  static Widget _defaultShimmer(double? width, double? height) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
