import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/home/booking_vehicle_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class VehicleAvailabilityScreen extends StatelessWidget {
  const VehicleAvailabilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle availability'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [VehicleCard(), SizedBox(height: 20), VehicleCard()],
      ),
    );
  }
}

class VehicleCard extends StatelessWidget {
  const VehicleCard({super.key});

  final String phone = "+918977778784";
  final String message = "Hello, I want to know more!";

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: Image.asset(
              'assets/images/vehicle_image.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: 150,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RouteCard(),
                const SizedBox(height: 16),
                Text(
                  'Seven Star Hatchery seeds',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      'Prakasam, Andhra Pradesh',
                      style: GoogleFonts.roboto(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Starting date',
                          style: GoogleFonts.roboto(color: Colors.grey),
                        ),
                        Text(
                          '23/06/2025',
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ending date',
                          style: GoogleFonts.roboto(color: Colors.grey),
                        ),
                        Text(
                          '25/06/2025',
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No.of space available',
                      style: GoogleFonts.roboto(color: Colors.grey),
                    ),
                    Text(
                      '5 Lakhs seeds',
                      style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    InkWell(
                      onTap: () => _makePhoneCall("+918977778784"),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            topLeft: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Image.asset('assets/images/phone.png', height: 20),
                            SizedBox(width: 4),
                            Text(
                              'Call Now',
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => openWhatsApp(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),

                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/images/whatsApp.png',
                              height: 20,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'WhatsApp',
                              style: GoogleFonts.roboto(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 4),

                    InkWell(
                      onTap: () {
                        Get.to(() => BookingVehicleScreen());
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),

                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Image.asset(
                              'assets/images/Lightning.png',
                              height: 20,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Book Now',
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> openWhatsApp(BuildContext context) async {
    final String phone = "+918977778784";
    final String message = "Hello, I want to know more!";
    // Build a properly encoded URI for the WhatsApp app scheme.
    final Uri whatsappUri = Uri(
      scheme: 'whatsapp',
      host: 'send',
      queryParameters: {'phone': phone, 'text': message},
    );

    // Fallback to web intent if app is not available.
    final Uri webFallback = Uri.https('api.whatsapp.com', '/send', {
      'phone': phone,
      'text': message,
    });

    try {
      // Try to open the WhatsApp native app using an external intent.
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        return;
      }

      // If native app isn't available, open the web fallback.
      if (await canLaunchUrl(webFallback)) {
        await launchUrl(webFallback, mode: LaunchMode.externalApplication);
        return;
      }

      // If neither can be launched, show a helpful message.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp is not available on this device.'),
          ),
        );
      }
    } catch (e, s) {
      debugPrint('Error opening WhatsApp: $e');
      debugPrint('Stack trace: $s');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening WhatsApp: $e')));
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    // Clean the phone number (remove any non-digit characters except +)
    final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleanedNumber.isEmpty) {
      debugPrint("Invalid phone number: $phoneNumber");
      return;
    }

    final Uri uri = Uri(scheme: 'tel', path: cleanedNumber);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint("Could not launch phone dialer for: $cleanedNumber");
      }
    } catch (e) {
      debugPrint("Error making phone call: $e");
    }
  }
}

class RouteCard extends StatelessWidget {
  const RouteCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF9FF), // light blue background
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Truck Icon
          const Icon(Icons.local_shipping, color: Colors.blue, size: 20),

          const SizedBox(width: 6),

          // Scrollable Route details (prevents overflow)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Puducherry
                  const Icon(Icons.location_on, color: Colors.blue, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "Puducherry",
                    style: GoogleFonts.roboto(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Dotted arrow substitute (Divider with arrow)
                  _buildArrow(),

                  // Vijayawada
                  const Icon(Icons.location_on, color: Colors.blue, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "Vijayawada",
                    style: GoogleFonts.roboto(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(width: 6),

                  _buildArrow(),

                  // Malappuram
                  const Icon(Icons.location_on, color: Colors.blue, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "Malappuram",
                    style: GoogleFonts.roboto(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Green check icon
          Image.asset('assets/images/success.png', height: 24),
        ],
      ),
    );
  }

  // Reusable arrow builder
  Widget _buildArrow() {
    return Row(
      children: const [
        SizedBox(width: 4, child: Divider(color: Colors.blue, thickness: 1)),
        SizedBox(width: 1),
        SizedBox(width: 4, child: Divider(color: Colors.blue, thickness: 1)),
        SizedBox(width: 1),
        SizedBox(width: 4, child: Divider(color: Colors.blue, thickness: 1)),
        Icon(Icons.arrow_forward, color: Colors.blue, size: 16),
      ],
    );
  }
}
