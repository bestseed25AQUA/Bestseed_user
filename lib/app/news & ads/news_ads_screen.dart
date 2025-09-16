import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/profile/profile_screen.dart';

class NewsAdsScreen extends StatelessWidget {
  const NewsAdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        automaticallyImplyLeading: false,
        title: Text(
          'News & Ads',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Image.asset('assets/images/lan_image.png', height: 32),
          SizedBox(width: 16),
          Image.asset('assets/images/notification.png', height: 32),
          SizedBox(width: 16),
          InkWell(
            onTap: () {
              Get.to(() => ProfileScreen());
            },
            child: Image.asset('assets/images/person.png', height: 32),
          ),
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Trending updates'),
            _buildTrendingSection(),
            const SizedBox(height: 20),
            _buildSectionHeader('Medicine news'),
            _buildMedicineNewsSection(),
            const SizedBox(height: 20),
            _buildSectionHeader('Climate news'),
            _buildClimateNewsSection(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTrendingSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      height: 200, // Adjust height as needed
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        image: const DecorationImage(
          image: NetworkImage(
            'https://picsum.photos/600/300?random=1',
          ), // Placeholder image
          fit: BoxFit.cover,
        ),
      ),
      child: const Center(
        child: Icon(Icons.play_circle_fill, color: Colors.white, size: 60),
      ),
    );
  }

  Widget _buildMedicineNewsSection() {
    return SizedBox(
      height: 180, // Adjust height to accommodate content
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        children: [
          _buildNewsCard(
            'Probiotic Powder',
            'Gutwell, Vibract',
            'https://picsum.photos/200/300?random=2', // Placeholder image
          ),
          _buildNewsCard(
            'Immuno Boosters',
            'ImmuGuard, Immuno',
            'https://picsum.photos/200/300?random=3', // Placeholder image
          ),
          _buildNewsCard(
            'Immuno Boosters',
            'ImmuGuard, Immuno',
            'https://picsum.photos/200/300?random=4', // Placeholder image
          ),
        ],
      ),
    );
  }

  Widget _buildClimateNewsSection() {
    return SizedBox(
      height: 180, // Adjust height to accommodate content
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        children: [
          _buildNewsCard(
            'Rising sea temperature',
            null, // No subtitle in the mock-up
            'https://picsum.photos/200/300?random=5', // Placeholder image
          ),
          _buildNewsCard(
            'Floods are ahead',
            null, // No subtitle in the mock-up
            'https://picsum.photos/200/300?random=6', // Placeholder image
          ),
          _buildNewsCard(
            'Tsunami Risk',
            null, // No subtitle in the mock-up
            'https://picsum.photos/200/300?random=7', // Placeholder image
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(String title, String? subtitle, String imageUrl) {
    return Container(
      width: 150,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              height: 120,
              width: 150,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
