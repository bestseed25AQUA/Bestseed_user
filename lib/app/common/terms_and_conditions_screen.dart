import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        titleString: 'Terms & Conditions',
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('1. Acceptance of Terms'),
            _SectionBody(
              'By accessing or using the BestSeed application ("App"), you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use the App.',
            ),
            _SectionTitle('2. Eligibility'),
            _SectionBody(
              'The BestSeed App is intended for farmers, aquaculture professionals, and individuals seeking hatchery and seed-related services. By registering, you confirm that:\n\n'
              '• You are at least 18 years of age.\n'
              '• All information you provide during registration is accurate and up to date.\n'
              '• You will use the App only for legitimate agricultural and aquaculture purposes.',
            ),
            _SectionTitle('3. Services'),
            _SectionBody(
              'BestSeed provides a platform connecting farmers and buyers with hatcheries, seed providers, and related service vendors. The App may include:\n\n'
              '• Browsing hatchery listings and seed availability.\n'
              '• Placing and managing bookings for seeds and aquaculture products.\n'
              '• Real-time vehicle tracking for your orders in transit.\n'
              '• Access to agricultural news, market prices, and updates.\n'
              '• Direct communication with vendors.',
            ),
            _SectionTitle('4. Bookings and Orders'),
            _SectionBody(
              'When you place a booking through the App:\n\n'
              '• You agree to provide accurate delivery location details.\n'
              '• Bookings are subject to vendor availability and confirmation.\n'
              '• Cancellation policies may apply depending on the vendor and booking type.\n'
              '• BestSeed acts as a facilitating platform and is not directly responsible for the quality of goods supplied by vendors.',
            ),
            _SectionTitle('5. User Responsibilities'),
            _SectionBody(
              'As a registered user, you agree to:\n\n'
              '• Maintain the confidentiality of your account credentials.\n'
              '• Not share your account with others.\n'
              '• Report any unauthorized access to your account immediately.\n'
              '• Not misuse the platform for fraudulent or unlawful activities.\n'
              '• Treat vendors and service providers with respect.',
            ),
            _SectionTitle('6. Location Data'),
            _SectionBody(
              'BestSeed may request access to your device location to:\n\n'
              '• Suggest nearby hatcheries and service providers.\n'
              '• Accurately determine your delivery address.\n'
              '• Track vehicles delivering your order in real time.\n\n'
              'Location access is optional and used only to enhance your experience. You may manage location permissions through your device settings.',
            ),
            _SectionTitle('7. Payments'),
            _SectionBody(
              'All payment transactions facilitated through the App are subject to the respective vendor\'s pricing and payment terms. BestSeed is not liable for pricing errors or disputes arising between users and vendors. Any complaints regarding payments should be directed to the vendor or BestSeed support.',
            ),
            _SectionTitle('8. Intellectual Property'),
            _SectionBody(
              'All content, logos, and materials within the App are the property of BestSeed and are protected by applicable intellectual property laws. You may not reproduce, distribute, or use any content from the App without prior written consent from BestSeed.',
            ),
            _SectionTitle('9. Termination'),
            _SectionBody(
              'BestSeed reserves the right to suspend or terminate your account at any time if you violate these Terms and Conditions or engage in conduct harmful to other users or the platform.',
            ),
            _SectionTitle('10. Limitation of Liability'),
            _SectionBody(
              'BestSeed shall not be liable for any indirect, incidental, or consequential damages arising from your use of the App, including but not limited to losses arising from vendor disputes, delivery delays, or product quality issues.',
            ),
            _SectionTitle('11. Changes to Terms'),
            _SectionBody(
              'BestSeed reserves the right to modify these Terms and Conditions at any time. Changes will be communicated through the App. Continued use of the App after changes constitutes your acceptance of the updated terms.',
            ),
            _SectionTitle('12. Contact Us'),
            _SectionBody(
              'If you have any questions about these Terms and Conditions, please contact BestSeed through the official support channels available in the App.',
            ),
            SizedBox(height: 32),
            Center(
              child: Text(
                'Last updated: April 2026',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2E7D32),
        ),
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  final String text;
  const _SectionBody(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black87,
        height: 1.6,
      ),
    );
  }
}
