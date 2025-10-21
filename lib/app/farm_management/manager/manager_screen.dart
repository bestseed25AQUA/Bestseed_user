import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_button.dart';

// Data model for a Manager
class Manager {
  final String name;
  final String phoneNumber;
  final bool canEdit;
  final bool canView;
  final bool canDelete;
  final bool canCreate;

  Manager(
    this.name,
    this.phoneNumber,
    this.canEdit,
    this.canView,
    this.canDelete,
    this.canCreate,
  );
}

// --- Manager List Screen ---
class ManagerScreen extends StatefulWidget {
  const ManagerScreen({super.key});

  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen> {
  final List<Manager> managers = [
    Manager('Raju Kollam', '8593845868', false, true, true, true),
    Manager('Raju Kumar', '9876543210', true, true, false, false),
    Manager('Anita Sharma', '9988776655', true, true, false, false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Manager', style: GoogleFonts.roboto(color: Colors.white)),
        actions: [
          InkWell(
            onTap: () => _showAddManagerDetails(context),
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
                    'Add Manager',
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
              'Manager Access with Phone Number',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...managers
                .map((manager) => ManagerCard(manager: manager))
                .toList(),
          ],
        ),
      ),
    );
  }

  void _showAddManagerDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
        ),
        child: const AddManagerDetailsForm(),
      ),
    );
  }
}

// --- Manager Card ---
class ManagerCard extends StatelessWidget {
  final Manager manager;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ManagerCard({
    super.key,
    required this.manager,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> accessButtons = [];
    if (manager.canEdit) {
      accessButtons.add(_buildAccessChip('Edit access', AppColors.primary));
    }
    if (manager.canView) {
      accessButtons.add(_buildAccessChip('View access', AppColors.primary));
    }
    if (manager.canDelete) {
      accessButtons.add(_buildAccessChip('Delete access', AppColors.primary));
    }
    if (manager.canCreate) {
      accessButtons.add(_buildAccessChip('Create access', AppColors.primary));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manager.name,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      manager.phoneNumber,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (value) {
                  if (value == 'edit') {
                    if (onEdit != null) onEdit!();
                  } else if (value == 'delete') {
                    if (onDelete != null) onDelete!();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 4, children: accessButtons),
        ],
      ),
    );
  }

  Widget _buildAccessChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GoogleFonts.roboto(fontSize: 12, color: color)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {},
            child: Icon(Icons.close, size: 14, color: color),
          ),
        ],
      ),
    );
  }
}

// --- Add Manager Modal ---

class AddManagerDetailsForm extends StatefulWidget {
  const AddManagerDetailsForm({super.key});

  @override
  State<AddManagerDetailsForm> createState() => _AddManagerDetailsFormState();
}

class _AddManagerDetailsFormState extends State<AddManagerDetailsForm> {
  // State for the radio buttons
  bool _canEdit = false;
  bool _canView = true; // Defaulted to YES as per the image
  bool _canDelete = false;
  bool _canCreate = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      // The modal has rounded top corners
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Essential for bottom sheet
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Manager Details',
                style: GoogleFonts.roboto(
                  fontSize: 18,
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

          // Person Name Field
          _buildFormLabel('Person Name'),
          TextField(decoration: _inputDecoration('Enter Person Name')),
          const SizedBox(height: 16),

          // Phone Number Field
          _buildFormLabel('Phone Number'),
          TextField(
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration('Enter Phone number'),
          ),
          const SizedBox(height: 24),

          // App Access Section
          _buildFormLabel('App Access', bold: true),
          const SizedBox(height: 10),

          // Access Radio Groups
          _buildAccessRadioGroup(
            'Do you want to give edit access to this Person ?',
            _canEdit,
            (bool? value) => setState(() => _canEdit = value!),
          ),
          _buildAccessRadioGroup(
            'Do you want to give view access to this Person ?',
            _canView,
            (bool? value) => setState(() => _canView = value!),
          ),
          _buildAccessRadioGroup(
            'Do you want to give Delete access to this Person ?',
            _canDelete,
            (bool? value) => setState(() => _canDelete = value!),
            labelColor: Colors.red,
          ),
          _buildAccessRadioGroup(
            'Do you want to give Create access to this Person ?',
            _canCreate,
            (bool? value) => setState(() => _canCreate = value!),
          ),
          const SizedBox(height: 30),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              onPressed: () {
                // Handle Save logic
                Navigator.pop(context);
              },

              text: 'Save',
            ),
          ),
          // Additional space for keyboard visibility if needed
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildAccessRadioGroup(
    String question,
    bool value,
    Function(bool?) onChanged, {
    Color labelColor = Colors.blue,
  }) {
    // Helper to extract the key access word for styling
    final RegExp accessWordRegExp = RegExp(
      r'\b(edit|view|delete|create)\b',
      caseSensitive: false,
    );
    final match = accessWordRegExp.firstMatch(question);
    final accessWord = match != null
        ? question.substring(match.start, match.end)
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Styled Question Text
          RichText(
            text: TextSpan(
              text: 'Do you want to give ',
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.black87),
              children: <TextSpan>[
                TextSpan(
                  text: accessWord,
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    color: labelColor,
                  ),
                ),
                TextSpan(
                  text: question.substring(
                    question.indexOf(accessWord) + accessWord.length,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: <Widget>[
              // Yes Radio
              Expanded(
                child: ListTile(
                  title: Text('Yes', style: GoogleFonts.roboto(fontSize: 14)),
                  leading: Radio<bool>(
                    value: true,
                    groupValue: value,
                    onChanged: onChanged,
                    activeColor: AppColors.primary,
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              // No Radio
              Expanded(
                child: ListTile(
                  title: Text('NO', style: GoogleFonts.roboto(fontSize: 14)),
                  leading: Radio<bool>(
                    value: false,
                    groupValue: value,
                    onChanged: onChanged,
                    activeColor: AppColors.primary,
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
