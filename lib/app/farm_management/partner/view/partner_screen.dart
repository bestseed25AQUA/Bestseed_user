import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/farm_management/partner/controller/partener_controller.dart';
import 'package:seedsuser/app/farm_management/partner/model/partner_list_model.dart';
import 'package:seedsuser/app/farm_management/partner/view/add_partner_screen.dart';

class PartnerScreen extends StatefulWidget {
  const PartnerScreen({super.key});

  @override
  State<PartnerScreen> createState() => _PartnerScreenState();
}

class _PartnerScreenState extends State<PartnerScreen> {
  final PartnerController controller = Get.put(PartnerController());

  @override
  void initState() {
    super.initState();
    controller.fetchPartners();
  }

  void _showEditPartner(BuildContext context, Partner partner) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
          ),
          child: AddPartnerDetailsForm(
            partner: partner,
            onSave: (_) => controller.fetchPartners(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Partners', style: GoogleFonts.roboto(color: Colors.white)),
        actions: [
          InkWell(
            onTap: () => _showAddPartnerDetails(context),
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
                    'Add Partner',
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
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Partner Access with Phone Number',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ...controller.partnerList.map(
                    (partner) => PartnerCard(
                      partner: partner,
                      onEdit: () => _showEditPartner(context, partner),

                      onRemoveAccess: (type) async {
                        bool success = await controller.removePartnerAccess(
                          id: partner.id.toString(),
                          accessType: type,
                        );
                        if (success) controller.fetchPartners();
                      },

                      onDelete: () async {
                        bool confirm = await showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text("Confirm Delete"),
                              content: Text(
                                "Are you sure you want to delete this partner?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text("Cancel"),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(
                                    "Delete",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirm == true) {
                          bool deleted = await controller.deletePartner(
                            id: partner.id.toString(),
                          );
                          if (deleted) controller.fetchPartners();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            if (controller.isAccessUpdating.value ||
                controller.isCreateLoading.value ||
                controller.isDeleting.value)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        );
      }),
    );
  }

  void _showAddPartnerDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
          ),
          child: AddPartnerDetailsForm(onSave: (_) => controller.fetchPartners()),
        ),
      ),
    );
  }
}

class PartnerCard extends StatelessWidget {
  final Partner partner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(String accessType)? onRemoveAccess;

  const PartnerCard({
    super.key,
    required this.partner,
    this.onEdit,
    this.onDelete,
    this.onRemoveAccess,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> accessButtons = [];

    if (partner.editAccess)
      accessButtons.add(
        _chip("Edit access", () {
          onRemoveAccess?.call("edit_access");
        }),
      );

    if (partner.viewAccess)
      accessButtons.add(
        _chip("View access", () {
          onRemoveAccess?.call("view_access");
        }),
      );

    if (partner.readAccess)
      accessButtons.add(
        _chip("Read access", () {
          onRemoveAccess?.call("read_access");
        }),
      );

    if (partner.createAccess)
      accessButtons.add(
        _chip("Create access", () {
          onRemoveAccess?.call("create_access");
        }),
      );

    if (partner.deleteAccess)
      accessButtons.add(
        _chip("Delete access", () {
          onRemoveAccess?.call("delete_access");
        }),
      );

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
                      partner.name,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      partner.phone,
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
                  if (value == 'edit') onEdit?.call();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
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

  Widget _chip(String label, VoidCallback onRemove) {
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.roboto(fontSize: 12, color: AppColors.primary),
            ),
            const SizedBox(width: 4),
            Icon(Icons.close, size: 14, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
