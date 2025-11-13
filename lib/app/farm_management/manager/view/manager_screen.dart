import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_button.dart';
import 'package:seedsuser/app/farm_management/manager/controller/manage_controller.dart';
import 'package:seedsuser/app/farm_management/manager/model/manager_list_model.dart';
import 'package:seedsuser/app/farm_management/manager/view/add_manager_screen.dart';

class ManagerScreen extends StatefulWidget {
  const ManagerScreen({super.key});

  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen> {
  final ManagerController controller = Get.put(ManagerController());

  @override
  void initState() {
    super.initState();
    controller.fetchManagers(); // Load data on screen open
  }

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
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
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

              ...controller.managerList
                  .map((manager) => ManagerCard(manager: manager))
                  .toList(),
            ],
          ),
        );
      }),
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
        child: AddManagerDetailsForm(
          onSave: (manager) {
            // controller.addManager(manager);
          },
        ),
      ),
    );
  }
}

// ===================== CARD UI (unchanged) =====================
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
    if (manager.canEdit) accessButtons.add(_chip("Edit access"));
    if (manager.canView) accessButtons.add(_chip("View access"));
    if (manager.canDelete) accessButtons.add(_chip("Delete access"));
    if (manager.canCreate) accessButtons.add(_chip("Create access"));

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
                  if (value == 'edit' && onEdit != null) onEdit!();
                  if (value == 'delete' && onDelete != null) onDelete!();
                },
                itemBuilder: (context) => const [
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

  Widget _chip(String label) {
    return Container(
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
    );
  }
}

// ===================== BOTTOM SHEET (unchanged, only Save integrated) =====================
