import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        titleString: 'Privacy Policy',
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('1. Introduction'),
            _SectionBody(
              'BestSeed ("we", "us", or "our") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your personal information when you use the BestSeed App.',
            ),
            _SectionTitle('2. Information We Collect'),
            _SectionBody(
              'We collect the following types of information:\n\n'
              'a) Account Information\n'
              '   • Mobile number (for OTP-based login)\n'
              '   • Name, farm details, and profile information\n\n'
              'b) Location Information\n'
              '   • Your device location (if permitted) to suggest nearby hatcheries\n'
              '   • Delivery address for order fulfillment\n\n'
              'c) Device Information\n'
              '   • Device model and OS version\n'
              '   • FCM token for push notifications\n\n'
              'd) Usage Information\n'
              '   • Booking history and order activity\n'
              '   • App interaction data for performance improvement',
            ),
            _SectionTitle('3. How We Use Your Information'),
            _SectionBody(
              'We use the collected information to:\n'
              '• Authenticate and manage your account.\n'
              '• Process and fulfill your bookings and orders.\n'
              '• Show nearby hatcheries and service providers.\n'
              '• Send push notifications for booking updates and alerts.\n'
              '• Provide real-time vehicle tracking for your orders.\n'
              '• Improve app performance and user experience.\n'
              '• Share relevant agricultural news and market price updates.\n'
              '• Comply with legal and regulatory requirements.',
            ),
            _SectionTitle('4. Location Data'),
            _SectionBody(
              'Location access is optional and used to:\n'
              '• Help you find hatcheries and service providers near you.\n'
              '• Set your delivery address more accurately.\n\n'
              'We do not track your location continuously in the background. Location is accessed only when you open the App or when you actively use location-based features.',
            ),
            _SectionTitle('5. Vehicle Tracking'),
            _SectionBody(
              'When your order is in transit, BestSeed provides real-time vehicle tracking so you can follow the delivery progress. This tracking is based on the delivery driver\'s location and is visible only for the duration of your active delivery.',
            ),
            _SectionTitle('6. Data Sharing'),
            _SectionBody(
              'We do not sell your personal information to third parties. We may share your information with:\n'
              '• Hatcheries and vendors to fulfill your bookings.\n'
              '• Delivery drivers for order completion.\n'
              '• Service providers who assist in operating the App (e.g., Firebase for push notifications).\n'
              '• Law enforcement or regulators when required by law.',
            ),
            _SectionTitle('7. Data Retention'),
            _SectionBody(
              'We retain your personal data for as long as your account is active or as needed to provide services. Booking records may be retained for up to 3 years for business and compliance purposes. You may request deletion of your data by contacting BestSeed support.',
            ),
            _SectionTitle('8. Data Security'),
            _SectionBody(
              'We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. All data is transmitted over secure encrypted connections.',
            ),
            _SectionTitle('9. Your Rights'),
            _SectionBody(
              'You have the right to:\n'
              '• Access the personal data we hold about you.\n'
              '• Request correction of inaccurate data.\n'
              '• Request deletion of your account and data (subject to legal obligations).\n'
              '• Opt out of push notifications through your device settings.\n\n'
              'To exercise these rights, please contact BestSeed support through the App.',
            ),
            _SectionTitle('10. Third-Party Services'),
            _SectionBody(
              'The App uses third-party services including Firebase (Google) for authentication, push notifications, and data storage. These services have their own privacy policies that govern their data handling practices.',
            ),
            _SectionTitle('11. Changes to This Policy'),
            _SectionBody(
              'We may update this Privacy Policy from time to time. We will notify you of significant changes through the App. Continued use of the App after changes constitutes your acceptance of the updated policy.',
            ),
            _SectionTitle('12. Contact Us'),
            _SectionBody(
              'If you have any questions or concerns about this Privacy Policy or our data practices, please contact BestSeed through the official support channels available in the App.',
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
