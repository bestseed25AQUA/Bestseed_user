import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/profile/profile_screen.dart';

class UpdatesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> posts = [
    {
      'name': 'Rama Hatchery',
      'logo': 'assets/images/rama.png',
      'time': 'a few hours ago',
      'text':
          'Rama Hatchery\'s new crop Srydqn farming #Aquaculture #Shrimp #Water #PremiumQuality #Seeds',
      'media': [
        'assets/images/rama.png',
        'assets/images/rama.png',
        'assets/images/rama.png',
      ],
    },
    {
      'name': 'Gayathri Hatchery',
      'logo': 'assets/images/rama.png',
      'time': 'new crop',
      'text':
          'Gayathri hatchery new crop Sry Hantline farming #Aquaculture #Shrimp #Water #PremiumQuality #Seeds',
      'media': ['assets/images/rama.png', 'assets/images/rama.png'],
    },
  ];

  UpdatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        automaticallyImplyLeading: false,
        title: Text(
          'Updates',
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Image.asset('assets/images/us.png'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return PostWidget(postData: posts[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PostWidget extends StatefulWidget {
  final Map<String, dynamic> postData;

  const PostWidget({super.key, required this.postData});

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 0.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage(widget.postData['logo']),
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.postData['name'],
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      widget.postData['time'],
                      style: GoogleFonts.roboto(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Post Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              widget.postData['text'],
              style: GoogleFonts.roboto(fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          // Media Carousel
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              SizedBox(
                height: 250,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.postData['media'].length,
                  itemBuilder: (context, index) {
                    return Image.asset(
                      widget.postData['media'][index],
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
              // Page Indicator Dots
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.postData['media'].length,
                    (index) => buildDot(index),
                  ),
                ),
              ),
            ],
          ),
          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset('assets/images/call.png', height: 38),
                    Image.asset('assets/images/whatsApp.png', height: 32),
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
  }

  Widget buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 6,
      width: _currentPage == index ? 12 : 6,
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.blue : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
