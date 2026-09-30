import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/safe_network_image.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/farm_banner_controller.dart';
import 'package:seedsuser/app/model/home_banner_model.dart';
import 'package:seedsuser/app/utils/network_utils.dart';
import 'package:url_launcher/url_launcher.dart';

/// Auto-scrolling banners across the top of the Farm Management screen.
class FarmBannerCarousel extends StatefulWidget {
  const FarmBannerCarousel({super.key});

  @override
  State<FarmBannerCarousel> createState() => _FarmBannerCarouselState();
}

class _FarmBannerCarouselState extends State<FarmBannerCarousel> {
  final controller = farmBannerController;

  int _current = 0;

  static const double _height = 150;

  @override
  void initState() {
    super.initState();
    controller.load();
  }

  Future<void> _open(BannerItem banner) async {
    final target = (banner.redirectUrl ?? '').trim();
    if (target.isEmpty) return;

    final uri = Uri.tryParse(target);
    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final banners = controller.banners;

      if (banners.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CarouselSlider.builder(
              itemCount: banners.length,
              options: CarouselOptions(
                height: _height,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 4),
                autoPlayAnimationDuration: const Duration(milliseconds: 600),
                enableInfiniteScroll: banners.length > 1,
                viewportFraction: 1,
                onPageChanged: (index, _) => setState(() => _current = index),
              ),
              itemBuilder: (context, index, _) {
                final banner = banners[index];

                return GestureDetector(
                  onTap: () => _open(banner),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SafeNetworkImage(
                      imageUrl: resolveMediaUrl(banner.url),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: _height,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(banners.length, (index) {
                final active = _current == index;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: active ? 18 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    });
  }
}
