import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

/// Network image widget that first tries Flutter's native [Image.network]
/// (fast, GPU-accelerated) and only falls back to a pure-Dart background
/// isolate decode when the native path fails.
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

    // DEBUG: red border to see if widget has size
    Widget child = SizedBox(
      width: width,
      height: height,
      child: Image.network(
        imageUrl,
        fit: fit,
        gaplessPlayback: true,
        loadingBuilder: (ctx, child, loadingProgress) {
          if (loadingProgress == null) {
            
            return child;
          }
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (ctx, error, stack) {
         
          return Center(
            child: Text(
              'ERR',
              style: TextStyle(color: Colors.red, fontSize: 10),
            ),
          );
        },
      ),
    );

    if (onTap != null) {
      child = GestureDetector(onTap: onTap, child: child);
    }
    return child;
  }
}

// ---------------------------------------------------------------------------
// Fallback: only used when native Image.network fails
// ---------------------------------------------------------------------------

class _IsolateFallback extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, Object)? onFinalError;

  const _IsolateFallback({
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.onFinalError,
  });

  @override
  State<_IsolateFallback> createState() => _IsolateFallbackState();
}

class _IsolateFallbackState extends State<_IsolateFallback> {
  late final Future<ui.Image?> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImage(widget.imageUrl);
  }

  static Future<ui.Image?> _loadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
       
        return null;
      }

      final pixels = await compute(
        _decodeInIsolate,
        _DecodeTask(response.bodyBytes),
      );
      if (pixels == null) {
       
        return null;
      }

      final buffer = await ui.ImmutableBuffer.fromUint8List(pixels.rgba);
      final descriptor = ui.ImageDescriptor.raw(
        buffer,
        width: pixels.width,
        height: pixels.height,
        pixelFormat: ui.PixelFormat.rgba8888,
      );
      final codec = await descriptor.instantiateCodec();
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e, stack) {
      debugPrint('SafeNetworkImage(fallback): error for $url\n$e\n$stack');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.Image?>(
      future: _imageFuture,
      builder: (ctx, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.placeholder?.call(ctx, widget.imageUrl) ??
              SizedBox(width: widget.width, height: widget.height);
        }

        if (snapshot.data != null) {
          return RawImage(
            image: snapshot.data,
            fit: widget.fit,
            width: widget.width,
            height: widget.height,
          );
        }

        return widget.onFinalError?.call(
              ctx,
              widget.imageUrl,
              Exception('decode failed'),
            ) ??
            widget.placeholder?.call(ctx, widget.imageUrl) ??
            SizedBox(width: widget.width, height: widget.height);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Background-isolate helpers (must be top-level / plain data)
// ---------------------------------------------------------------------------

class _DecodeTask {
  final Uint8List bytes;
  const _DecodeTask(this.bytes);
}

class _DecodedPixels {
  final Uint8List rgba;
  final int width;
  final int height;
  const _DecodedPixels(this.rgba, this.width, this.height);
}

_DecodedPixels? _decodeInIsolate(_DecodeTask task) {
  final decoded = img.decodeImage(task.bytes);
  if (decoded == null) return null;

  final img.Image rgba;
  if (decoded.numChannels == 4 && decoded.bitsPerChannel == 8) {
    rgba = decoded;
  } else {
    rgba = decoded.convert(numChannels: 4, format: img.Format.uint8);
  }

  return _DecodedPixels(
    Uint8List.fromList(rgba.getBytes(order: img.ChannelOrder.rgba)),
    rgba.width,
    rgba.height,
  );
}
