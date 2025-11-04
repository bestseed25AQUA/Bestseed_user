import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/news%20&%20ads/view/medicine_details.dart';

class MedicineNewsScreen extends StatefulWidget {
  const MedicineNewsScreen({super.key});

  @override
  State<MedicineNewsScreen> createState() => _MedicineNewsScreenState();
}

class _MedicineNewsScreenState extends State<MedicineNewsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> allNews = [];
  List<Map<String, String>> filteredNews = [];

  @override
  void initState() {
    super.initState();

    // Sample news data
    allNews = List.generate(10, (index) {
      return {
        "title": "New Medicine Discovery $index",
        "subtitle": "Scientists have discovered a new medicine that...",
        "image": "https://picsum.photos/200/300?random=$index",
      };
    });

    filteredNews = List.from(allNews);
  }

  void _filterNews(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredNews = List.from(allNews);
      } else {
        filteredNews = allNews
            .where(
              (item) =>
                  item["title"]!.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
        title: Text(
          'Medicine News',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // 🔍 Search Field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterNews,
                decoration: InputDecoration(
                  hintText: 'Search medicine news...',
                  prefixIcon: const Icon(Icons.search),
                  // filled: true,
                  // fillColor: Colors.grey[200],
                  // contentPadding: const EdgeInsets.symmetric(
                  //   horizontal: 16,
                  //   vertical: 16,
                  // ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // 📰 Grid of News
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
                childAspectRatio: 1,
              ),
              itemCount: filteredNews.length,
              itemBuilder: (context, index) {
                final news = filteredNews[index];
                return InkWell(
                  onTap: () {
                    Get.to(
                      () => MedicineDetailScreen(title: news["title"] ?? ""),
                    );
                  },
                  child: _buildNewsCard(
                    news["title"] ?? "",
                    news["subtitle"] ?? "",
                    news["image"] ?? "",
                  ),
                );
              },
            ),
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
              width: double.infinity,
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
