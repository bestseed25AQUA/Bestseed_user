import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class MedicineDetailScreen extends StatefulWidget {
  final String title;
  const MedicineDetailScreen({super.key, required this.title});

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  String _whatsappNumber = '918977778784';

  // Optional: Define a pre-filled message
  String _initialMessage = 'Hello, I am interested in the Probiotic Powder.';

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
          Expanded(
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
                        child: Image.asset('assets/images/medicine.png'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Title and Brand
                  Text(
                    'Probiotic Powder',
                    style: GoogleFonts.roboto(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Gutwell, Vibract',
                    style: GoogleFonts.roboto(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16.0),

                  // Description/Details Section
                  Text(
                    'Gutwell Powder — What It Is',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Gutwell is a digestive supplement (powder form) for dogs and cats. Anim*l+2SpMedEx+2',
                    style: GoogleFonts.roboto(fontSize: 15),
                  ),
                  const SizedBox(height: 10.0),

                  // Key Combinations/Ingredients (Using bullet points for representation)
                  _buildIngredientSection('It combines:', [
                    'Probiotics: Saccharomyces cerevisiae, S. boulardii, and a Lactobacillus complex (like L. acidophilus, L. casei, L. rhamnosus) Animk*rt.com+3Paw Store+3SpMedEx+3',
                    'Prebiotics: Fructo-Oligo-Saccharides & Mannan Oligo Saccharide — these feed the good bacteria, helping them grow. SpMedEx+2Paw Store+2',
                    'Enzyme Complex: things like Protease, Lipase, Amylase, Beta-Glucanase, Cellulase, Hemicellulase, Pectinase. These help break down proteins, fats, carbs, fiber etc. Paw Store+1',
                  ]),
                  const SizedBox(height: 10.0),

                  // CFU/Prebiotic info
                  Text(
                    'Each gram gives around 800 million CFU of probiotics (i.e. high potency) and ~20 mg prebiotics. Anim*l /+2SpMedEx+2',
                    style: GoogleFonts.roboto(fontSize: 15),
                  ),
                  const SizedBox(height: 10.0),
                  Text(
                    'Uses / Benefits',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Here are the main advantages & use-cases:',
                    style: GoogleFonts.roboto(fontSize: 15),
                  ),
                  // More text content would follow here...
                ],
              ),
            ),
          ),

          // Action Buttons Section (Fixed at the bottom)
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                // Call Now Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Logic for calling
                      _makePhoneCall('tel:+918977778784');
                    },
                    icon: const Icon(Icons.call, color: Colors.white),
                    label: Text(
                      'Call Now',
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // WhatsApp Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _launchWhatsApp();
                    },
                    icon: Image.asset(
                      'assets/images/whatsApp.png',
                      height: 20,
                      width: 20,
                    ),
                    label: Text(
                      'WhatsApp',
                      style: GoogleFonts.roboto(
                        color: Colors.green,
                        fontSize: 16,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      // The image's WhatsApp button looks like a light green background,
                      // so we'll adjust the style slightly.
                      backgroundColor: Colors.white, // Or a very light green
                    ),
                  ),
                ),
              ],
            ),
          ),
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
