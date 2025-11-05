import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/custom_network_image.dart';
import 'package:seedsuser/app/news%20&%20ads/controller/single_new_detail_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class ClimateDetailScreen extends StatefulWidget {
  final String id;
  final String title;
  const ClimateDetailScreen({super.key, required this.id, required this.title});

  @override
  State<ClimateDetailScreen> createState() => _ClimateDetailScreenState();
}

class _ClimateDetailScreenState extends State<ClimateDetailScreen> {
  final String _whatsappNumber = '918977778784';

  // Optional: Define a pre-filled message
  final String _initialMessage =
      'Hello, I am interested in the Probiotic Powder.';
  final singleNewDetailController = Get.put(SingleNewDetailController());
  @override
  void initState() {
    singleNewDetailController.fetch(type: "climate news", id: widget.id);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        // automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            radius: 30,
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
          widget.title,
          style: GoogleFonts.roboto(color: Colors.white),
        ),
      ),
      body: Column(
        children: <Widget>[
          // Scrollable content area
          Obx(() {
            if (singleNewDetailController.singleDetailData.value == null ||
                singleNewDetailController.isLoading.value) {
              return Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * .3,
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: Builder(
                    builder: (context) {
                      if (singleNewDetailController.isLoading.value) {
                        return CircularProgressIndicator();
                      } else {
                        return Text('Something Went wrong');
                      }
                    },
                  ),
                ),
              );
            }
            final data = singleNewDetailController.singleDetailData.value;
            return Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Product Image Section
                    Center(
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CustomNetworkImage(
                            imageUrl: data?.data?.mediaPath ?? '',
                            fit: BoxFit.cover,
                          ),
                          // child: Image.asset('assets/images/default_image.png'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Title and Brand
                    Text(
                      data?.data?.title ?? '',
                      style: GoogleFonts.roboto(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      data?.data?.caption ?? '',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Description/Details Section
                    Text(
                      data?.data?.description ?? '',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Function to launch WhatsApp
  Future<void> _launchWhatsApp() async {
    // Use the wa.me link for maximum compatibility
    final String url =
        'https://wa.me/$_whatsappNumber?text=${Uri.encodeComponent(_initialMessage)}';

    final Uri launchUri = Uri.parse(url);

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback: Show an error if WhatsApp can't be opened
      // You might show a snackbar or dialog here
      throw 'Could not launch WhatsApp for $_whatsappNumber';
    }
  }

  Future<void> _makePhoneCall(String url) async {
    final Uri launchUri = Uri(
      scheme: 'tel', // The 'tel' scheme is used for phone numbers
      path: url,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // Optionally, show a snackbar or alert if the dialer can't be launched
      throw 'Could not launch $launchUri';
    }
  }

  // Helper function to build the bulleted list section
  Widget _buildIngredientSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: GoogleFonts.roboto(fontSize: 15)),
                Expanded(
                  child: Text(item, style: GoogleFonts.roboto(fontSize: 15)),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
