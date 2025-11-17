import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/custom_button.dart';
import 'package:seedsuser/app/farm_management/partner/controller/partener_controller.dart';
import 'package:seedsuser/app/farm_management/partner/model/partner_list_model.dart';

class AddPartnerDetailsForm extends StatefulWidget {
  final Function(Partner partner)? onSave;
  final Partner? partner;

  const AddPartnerDetailsForm({super.key, this.onSave, this.partner});

  @override
  State<AddPartnerDetailsForm> createState() => _AddPartnerDetailsFormState();
}

class _AddPartnerDetailsFormState extends State<AddPartnerDetailsForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Access Permissions
  bool _canEdit = false;
  bool _canView = true;
  bool _canDelete = false;
  bool _canCreate = false;
  bool _canRead = true;

  @override
  void initState() {
    super.initState();

    if (widget.partner != null) {
      final p = widget.partner!;

      _nameController.text = p.name;
      _phoneController.text = p.phone;

      _canEdit = p.editAccess;
      _canView = p.viewAccess;
      _canDelete = p.deleteAccess;
      _canCreate = p.createAccess;
      _canRead = p.readAccess;
    }
  }

  final controller = Get.put(PartnerController());
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------ Header -------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.partner == null
                      ? "Add Partner Details"
                      : "Edit Partner Details",
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

            // ------------ Name -------------
            _label("Partner Name"),
            TextField(
              controller: _nameController,
              decoration: _input("Enter Partner Name"),
            ),
            const SizedBox(height: 16),

            // ------------ Phone -------------
            _label("Phone Number"),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: _input("Enter Phone Number"),
            ),
            const SizedBox(height: 24),

            // ------------ Access Section -------------
            _label("App Access", bold: true),
            const SizedBox(height: 10),

            // _access(
            //   "Give Read Access?",
            //   _canRead,
            //   (v) => setState(() => _canRead = v!),
            // ),
            _access(
              "Do you want to give view access to this Person ?",
              _canView,
              (v) => setState(() => _canView = v!),
            ),
            _access(
              "Do you want to give edit access to this Person ?",
              _canEdit,
              (v) => setState(() => _canEdit = v!),
            ),

            // _access(
            //   "Give Delete Access?",
            //   _canDelete,
            //   (v) => setState(() => _canDelete = v!),
            //   labelColor: Colors.red,
            // ),
            // _access(
            //   "Give Create Access?",
            //   _canCreate,
            //   (v) => setState(() => _canCreate = v!),
            // ),
            const SizedBox(height: 30),

            // ------------ Save Button -------------
            Obx(() {
              return CustomButton(
                text: "Save",
                isLoading: controller.isCreateLoading.value,
                onPressed: controller.isCreateLoading.value
                    ? () {}
                    : () async {
                        bool success = await controller.createPartner(
                          name: _nameController.text.trim(),
                          phone: _phoneController.text.trim(),
                          viewAccess: _canView,
                          editAccess: _canEdit,
                          id: widget.partner?.id.toString(),
                        );

                        if (success) {
                          controller.fetchPartners();
                          Navigator.pop(context);
                        }
                      },
              );
            }),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ---------- Helper Widgets ----------

  Widget _label(String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

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
    String title,
    bool value,
    Function(bool?) onChanged, {
    Color labelColor = Colors.blue,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.roboto(fontSize: 14, color: labelColor),
          ),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  dense: true,
                  title: const Text("Yes"),
                  leading: Radio(
                    value: true,
                    groupValue: value,
                    onChanged: onChanged,
                  ),
                ),
              ),
              Expanded(
                child: ListTile(
                  dense: true,
                  title: const Text("No"),
                  leading: Radio(
                    value: false,
                    groupValue: value,
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
