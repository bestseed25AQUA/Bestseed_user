// --- Custom Contact Us Dialog Widget ---
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ContactUsDialog extends StatelessWidget {
  const ContactUsDialog({super.key});

  // The number to be used for calling and WhatsApp
  final String phoneNumber = '9704756582';

  // In a real app, you would use 'url_launcher' package for these actions.
  void _launchWhatsApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Launching WhatsApp... (Need url_launcher)'),
      ),
    );
  }

  void _launchCall(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Launching Call... (Need url_launcher)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      // Dialog shape with rounded corners
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor:
          Colors.transparent, // Background will be controlled by the inner Card
      child: Stack(
        alignment: Alignment.topRight,
        children: <Widget>[
          // The main content card
          Container(
            padding: const EdgeInsets.only(
              top: 20,
              left: 16,
              right: 16,
              bottom: 20,
            ),
            margin: const EdgeInsets.only(
              top: 10,
            ), // Space for the close button
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // To make the dialog compact
              children: <Widget>[
                // Title
                Text(
                  'Contact Us',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D6EFD), // Bright blue
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // 3D Image Placeholder (Use AssetImage in a real app)
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Image.asset(
                    'assets/images/Rectangle 3463568.png', // Placeholder image path
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.headset_mic,
                      size: 80,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sub-heading text
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    'Need Support? Our Helpline Is Just a Call Away',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Phone Number
                Text(
                  phoneNumber,
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons Row
                Row(
                  children: <Widget>[
                    // WhatsApp Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _launchWhatsApp(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.green, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/whatsApp.png',
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'WhatsApp',
                              style: GoogleFonts.roboto(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Call Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _launchCall(context),
                        icon: const Icon(Icons.call, color: Colors.white),
                        label: Text(
                          'Call',
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF0D6EFD,
                          ), // Bright blue
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Close Button (Positioned on top right)
          Positioned(
            top: 16,
            right: 10,
            child: Material(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(15),
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(15),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.close, color: Colors.black54, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showContactUsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return const ContactUsDialog();
    },
  );
}
