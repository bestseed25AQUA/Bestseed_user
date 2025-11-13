import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_button.dart';
import 'package:seedsuser/app/farm_management/manager/controller/manage_controller.dart';
import 'package:seedsuser/app/farm_management/manager/model/manager_list_model.dart';

class AddManagerDetailsForm extends StatefulWidget {
  final Function(Manager manager) onSave;

  const AddManagerDetailsForm({super.key, required this.onSave});

  @override
  State<AddManagerDetailsForm> createState() => _AddManagerDetailsFormState();
}

class _AddManagerDetailsFormState extends State<AddManagerDetailsForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _canEdit = false;
  bool _canView = true;
  bool _canDelete = false;
  bool _canCreate = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Add Manager Details",
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

            _label("Person Name"),
            TextField(
              controller: _nameController,
              decoration: _input("Enter Person Name"),
            ),
            const SizedBox(height: 16),

            _label("Phone Number"),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: _input("Enter Phone number"),
            ),
            const SizedBox(height: 24),

            _label("App Access", bold: true),
            const SizedBox(height: 10),

            _access(
              "Do you want to give edit access to this Person ?",
              _canEdit,
              (v) => setState(() => _canEdit = v!),
            ),
            _access(
              "Do you want to give view access to this Person ?",
              _canView,
              (v) => setState(() => _canView = v!),
            ),
            _access(
              "Do you want to give Delete access to this Person ?",
              _canDelete,
              (v) => setState(() => _canDelete = v!),
              labelColor: Colors.red,
            ),
            _access(
              "Do you want to give Create access to this Person ?",
              _canCreate,
              (v) => setState(() => _canCreate = v!),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: "Save",
                onPressed: () async {
                  final controller = Get.put(ManagerController());

                  bool success = await controller.createManager(
                    personName: _nameController.text.trim(),
                    phoneNumber: _phoneController.text.trim(),
                    canEdit: _canEdit,
                    canView: _canView,
                    canDelete: _canDelete,
                    canCreate: _canCreate,
                  );

                  if (success) {
                    widget.onSave(
                      Manager(
                        name: _nameController.text.trim(),
                        phoneNumber: _phoneController.text.trim(),
                        canEdit: _canEdit,
                        canView: _canView,
                        canDelete: _canDelete,
                        canCreate: _canCreate,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _label(String title, {bool bold = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(
      title,
      style: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      ),
    ),
  );

  InputDecoration _input(String hint) => InputDecoration(
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

  Widget _access(
    String question,
    bool value,
    Function(bool?) onChanged, {
    Color labelColor = Colors.blue,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: GoogleFonts.roboto(fontSize: 14, color: labelColor),
          ),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: Text("Yes"),
                  leading: Radio(
                    value: true,
                    groupValue: value,
                    onChanged: onChanged,
                  ),
                  dense: true,
                ),
              ),
              Expanded(
                child: ListTile(
                  title: Text("No"),
                  leading: Radio(
                    value: false,
                    groupValue: value,
                    onChanged: onChanged,
                  ),
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
