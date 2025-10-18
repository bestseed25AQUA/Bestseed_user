import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/seed_request/view/seed_request_screen.dart';
import 'package:seedsuser/app/home/view/vehicle_availability_screen.dart';

class CarouselCardsScreen extends StatefulWidget {
  const CarouselCardsScreen({super.key});

  @override
  _CarouselCardsScreenState createState() => _CarouselCardsScreenState();
}

class _CarouselCardsScreenState extends State<CarouselCardsScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> cards = [
      buildCard(
        title: 'Vehicle \nAvailability',
        icon: 'assets/images/truck.png',
        overlayIcon: 'assets/images/roya.png',
        onTap: () => Get.to(() => VehicleAvailabilityScreen()),
      ),
      buildCard(
        title: 'Seeds Requests',
        icon: 'assets/images/seeds.png',
        onTap: () => Get.to(() => SeedRequestsFormScreen()),
      ),
    ];

    return SizedBox(
      height: 160, // Card height + dot space
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CarouselSlider(
            options: CarouselOptions(
              height: 150,
              enlargeCenterPage: true,
              enableInfiniteScroll: false,
              autoPlay: true,
              viewportFraction: 0.8,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
            items: cards,
          ),
          Positioned(
            bottom: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: cards.asMap().entries.map((entry) {
                return Container(
                  width: 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == entry.key
                        ? Colors
                              .blue // Active dot
                        : Colors.grey, // Inactive dot
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCard({
    required String title,
    required String icon,
    String? overlayIcon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        // margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.roboto(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_circle_right, color: Colors.black, size: 24),
            const SizedBox(width: 10),
            overlayIcon != null
                ? Stack(
                    children: [
                      Image.asset(icon, height: 80),
                      Positioned(
                        top: 28,
                        left: 32,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(overlayIcon, height: 20),
                        ),
                      ),
                    ],
                  )
                : Image.asset(icon, height: 80),
          ],
        ),
      ),
    );
  }
}
