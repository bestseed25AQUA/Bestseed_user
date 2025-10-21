import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_button.dart';

// --- Partners List Screen ---
class PartnersScreen extends StatelessWidget {
  const PartnersScreen({super.key});

  // Dummy list of partners data
  final List<Map<String, String>> partners = const [
    {'name': 'Raju Kumar Kollam', 'phone': '8593845868'},
    {'name': 'Anita Sharma', 'phone': '9876543210'},
    {'name': 'Vikram Singh', 'phone': '9988776655'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_circle_left, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Partners'),
        actions: [
          InkWell(
            onTap: () => _showAddPartnersDialog(context),
            child: Container(
              margin: const EdgeInsets.only(right: 8.0),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add, color: AppColors.primary, size: 20),
                  Text(
                    'Add Partners',
                    style: GoogleFonts.roboto(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Partners access with Phone Number',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ...partners.map(
              (partner) =>
                  PartnerCard(name: partner['name']!, phone: partner['phone']!),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPartnersDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const Padding(
          padding: EdgeInsets.only(top: 80.0),
          child: AddPartnersDetailsSheet(),
        );
      },
    );
  }
}

// --- Partner Card using Container ---
class PartnerCard extends StatelessWidget {
  final String name;
  final String phone;

  const PartnerCard({super.key, required this.name, required this.phone});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name and phone
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(phone, style: GoogleFonts.roboto(color: Colors.grey)),
                ],
              ),
              const Icon(Icons.more_vert, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          // Access chips
          Row(
            children: [
              _buildAccessChip(context, 'Edit Access', Colors.blue),
              const SizedBox(width: 8),
              _buildAccessChip(context, 'View Access', Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccessChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GoogleFonts.roboto(fontSize: 12, color: color)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              // Handle remove access
            },
            child: Icon(Icons.close, size: 14, color: color),
          ),
        ],
      ),
    );
  }
}

// --- Add Partner Sheet ---
class AddPartnersDetailsSheet extends StatefulWidget {
  const AddPartnersDetailsSheet({super.key});

  @override
  State<AddPartnersDetailsSheet> createState() =>
      _AddPartnersDetailsSheetState();
}

class _AddPartnersDetailsSheetState extends State<AddPartnersDetailsSheet> {
  bool _giveEditAccess = true;
  bool _giveViewAccess = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Partners Details',
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Person Name
          // Person Name Field
          Text(
            'Person Name',
            style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'Enter Person Name',
              filled: true,
              fillColor: Colors.grey.shade200,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Phone Number Field
          Text(
            'Phone Number',
            style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextField(
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Enter Phone number',
              filled: true,
              fillColor: Colors.grey.shade200,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 20),
          // App Access
          Text(
            'App Access',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text('Do you want to give edit access to this Person?'),
          Row(
            children: [
              _buildRadioOption('Yes', true, _giveEditAccess, (value) {
                setState(() {
                  _giveEditAccess = value;
                });
              }),
              _buildRadioOption('No', false, _giveEditAccess, (value) {
                setState(() {
                  _giveEditAccess = value;
                });
              }),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Do you want to give view access to this Person?'),
          Row(
            children: [
              _buildRadioOption('Yes', true, _giveViewAccess, (value) {
                setState(() {
                  _giveViewAccess = value;
                });
              }),
              _buildRadioOption('No', false, _giveViewAccess, (value) {
                setState(() {
                  _giveViewAccess = value;
                });
              }),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              onPressed: () => Navigator.pop(context),
              text: 'Save',
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildRadioOption(
    String label,
    bool value,
    bool groupValue,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<bool>(
          value: value,
          groupValue: groupValue,
          onChanged: (val) => onChanged(val!),
          activeColor: Colors.blue,
        ),
        Text(label),
        const SizedBox(width: 10),
      ],
    );
  }
}
