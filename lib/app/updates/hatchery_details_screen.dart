import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';

class HatcheryDetailsScreen extends StatefulWidget {
  const HatcheryDetailsScreen({super.key});

  @override
  State<HatcheryDetailsScreen> createState() => _HatcheryDetailsScreenState();
}

class _HatcheryDetailsScreenState extends State<HatcheryDetailsScreen> {
  int _currentIndex = 0;

  final List<String> imageList = [
    'assets/images/WhatsApp Image 2025-10-04 at 1.24.19 PM.jpeg',
    'assets/images/WhatsApp Image 2025-10-04 at 1.24.17 PM.jpeg',
    'assets/images/rama.png',
    'assets/images/rama.png',
    'assets/images/rama.png',
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          /// Collapsible AppBar with Header section
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            automaticallyImplyLeading: true,
            iconTheme: IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 68),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                ClipOval(
                                  child: Image.asset(
                                    'assets/images/rama.png',
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Text(
                                  'Rama Hatchery',
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16.0),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Color(0xFF0076BE),
                                  size: 18,
                                ),
                                SizedBox(width: 4.0),
                                Text(
                                  'Bapatla unit- 2',
                                  style: GoogleFonts.roboto(
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          /// Post details list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipOval(
                            child: Image.asset(
                              'assets/images/rama.png',
                              width: 30,
                              height: 30,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            'Rama Hatchery',
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Posted 2 days ago',
                            style: GoogleFonts.roboto(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        'Rama Hatchery\'s new crop SyAqua farming 🦐.....'
                        '#Aquaculture #Shrimp #Water #Premium Quality Seeds',
                        style: GoogleFonts.roboto(fontSize: 16),
                      ),
                      const SizedBox(height: 16.0),
                      CarouselSlider(
                        items: imageList.map((imagePath) {
                          return Stack(
                            children: [
                              /// Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.asset(
                                  imagePath,
                                  width: double.infinity,
                                  height: 250,
                                  fit: BoxFit.cover,
                                ),
                              ),

                              /// Dots Positioned at bottom-center
                              Positioned(
                                bottom: 12,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    imageList.length,
                                    (dotIndex) => Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4.0,
                                      ),
                                      width: _currentIndex == dotIndex
                                          ? 10.0
                                          : 8.0,
                                      height: _currentIndex == dotIndex
                                          ? 10.0
                                          : 8.0,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _currentIndex == dotIndex
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                        options: CarouselOptions(
                          height: 250,
                          viewportFraction: 1.0,
                          enableInfiniteScroll: true,
                          autoPlay: true,
                          onPageChanged: (index, reason) {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    final phoneNumber = "tel:+918977778784";
                                    if (await canLaunch(phoneNumber)) {
                                      await launch(phoneNumber);
                                    } else {
                                      print("Could not launch phone call.");
                                    }
                                  },
                                  child: Image.asset(
                                    'assets/images/call.png',
                                    height: 38,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Image.asset(
                                  'assets/images/whatsApp.png',
                                  height: 32,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.facebook),
                                  onPressed: () {},
                                  color: Colors.blue.shade800,
                                ),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.share, size: 18),
                              label: const Text('Share'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              childCount: 8, // number of posts
            ),
          ),
        ],
      ),
    );
  }
}
