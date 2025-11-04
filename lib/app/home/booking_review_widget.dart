import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/custom_button.dart';

class BookingReviewContent extends StatelessWidget {
  const BookingReviewContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // 👈 FIX
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Review Bookings',
                style: GoogleFonts.roboto(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      color: Colors.grey[300],
                      child: const Icon(Icons.star_border, color: Colors.green),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Seven Start Hatchery',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInfoRow('Name', 'Sumanth'),
                const Divider(),
                _buildInfoRow('Phone Number', '917843765465'),
                const Divider(),
                _buildInfoRow('Unit', 'Vizag'),
                const Divider(),
                _buildInfoRow('No.of Pieces', '800 Pieces'),
                const Divider(),
                _buildInfoRow(
                  'Pickup location',
                  '9.159, Vizag, Andhra Pradesh',
                ),
                const Divider(),
                _buildInfoRow('Preferred Date', '28/09/2025'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          CustomButton(
            onPressed: () {
              Get.back();
              _showAlertDialog(context);
            },

            text: 'Proceed',
          ),
        ],
      ),
    );
  }

  // Function to show the alert dialog
  void _showAlertDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/SealCheck.png',
                height: 109,
                width: 109,
              ),
              SizedBox(height: 16),
              Text(
                'Your \nrequest was sent',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'We will notify your booking status \nwithin 24 Hours',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(color: Colors.grey[600], fontSize: 16),
          ),
          Flexible(
            // 👈 prevent text overflow
            child: Text(
              value,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
