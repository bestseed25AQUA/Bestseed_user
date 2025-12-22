import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ImageCarousel extends StatelessWidget {
  final List<String> images;
  final double height;
  final double viewportFraction;
  final bool isNetwork;
  final String placeHolder;

  const ImageCarousel({
    super.key,
    required this.images,
    this.height = 150,
    this.viewportFraction = 1,//0.85,
    this.isNetwork = false, required this.placeHolder,
  });

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      options: CarouselOptions(
        height: height,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: viewportFraction,
        enableInfiniteScroll: true,
        autoPlayInterval: const Duration(seconds: 3),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        scrollDirection: Axis.horizontal,
      ),
      items: images.map((img) {
        return isNetwork
            ? Image.network(
                img,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(placeHolder,  fit: BoxFit.cover,
                height: double.infinity,);
                },
              )
            : Image.asset(
                img,
                fit: BoxFit.cover,
                height: double.infinity,
              );
      }).toList(),
    );
  }
}
