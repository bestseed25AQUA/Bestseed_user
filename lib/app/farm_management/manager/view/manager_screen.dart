import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_button.dart';
import 'package:seedsuser/app/farm_management/manager/controller/manager_controller.dart';
import 'package:seedsuser/app/farm_management/manager/model/manager_list_model.dart';
import 'package:seedsuser/app/farm_management/manager/view/add_manager_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/farm_shimmer.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/farm_empty_state.dart';

class ManagerScreen extends StatefulWidget {
  /// Set when the screen is opened from a specific farm. Null from the
  /// farm-less entry point, where the list falls back to every manager on the
  /// farms this farmer owns.
  final int? farmId;

  const ManagerScreen({super.key, this.farmId});

  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen> {
  final ManagerController controller = Get.put(ManagerController());

  @override
  void initState() {
    super.initState();
    controller.fetchManagers(farmId: widget.farmId); // Load data on screen open
  }

  void _showEditManager(BuildContext context, Manager manager) {
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
          child: AddManagerDetailsForm(
            farmId: widget.farmId,
            manager: manager, // 👈 PASSED FOR PREFILL
            onSave: (m) {
              controller.fetchManagers(farmId: widget.farmId);
            },
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
          // Black, not white: CustomAppBar ignores the `backgroundColor` we
          // pass and always renders a WHITE bar, so a white arrow was
          // invisible — the button was there, it just could not be seen.
          icon: const Icon(Icons.arrow_back, color: Colors.black),
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
          return const ListTileShimmer();
        }
        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The section label only makes sense above an actual
                  // list; with nothing to label it just floats over a blank
                  // page above the empty state.
                  if (controller.managerList.isNotEmpty) ...[
                    Text(
                      'Manager Access with Phone Number',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Nothing to list yet: say so, and offer the one
                  // action that makes sense here.
                  if (controller.managerList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: FarmEmptyState(
                        icon: Icons.manage_accounts_outlined,
                        title: 'No managers yet',
                        message:
                            'Add a manager to let someone help run this farm — you choose exactly what they can see and change.',
                        actionLabel: 'Add Manager',
                        onAction: () => _showAddManagerDetails(context),
                      ),
                    ),
                  ...controller.managerList.map(
                    (manager) => ManagerCard(
                      manager: manager,
                      onEdit: () => _showEditManager(context, manager),
                      onRemoveAccess: (accessType) async {
                        bool isRemove = await controller.removeAccess(
                          id: manager.id.toString(),
                          accessType: accessType,
                        );
                        if (isRemove) {
                          controller.fetchManagers(farmId: widget.farmId);
                        }
                      },
                      onDelete: () async {
                        bool confirm = await showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text("Confirm Delete"),
                              content: Text(
                                "Are you sure you want to delete this manager?",
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
                          bool isDeleted = await controller.deleteManager(
                            id: manager.id.toString(),
                          );

                          if (isDeleted) {
                            controller.fetchManagers(farmId: widget.farmId);
                          }
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
                // ignore: deprecated_member_use
                color: Colors.black.withOpacity(
                  0.4,
                ), // Dark transparent overlay
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        );
      }),
    );
  }

  void _showAddManagerDetails(BuildContext context) {
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
          child: AddManagerDetailsForm(
            farmId: widget.farmId,
            onSave: (manager) {},
          ),
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
  final Function(String accessType)? onRemoveAccess;
  const ManagerCard({
    super.key,
    required this.manager,
    this.onEdit,
    this.onDelete,
    this.onRemoveAccess,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> accessButtons = [];
    if (manager.editAccess) {
      accessButtons.add(
        _chip("Edit access", () {
          if (onRemoveAccess != null) onRemoveAccess!("edit_access");
        }),
      );
    }

    if (manager.viewAccess) {
      accessButtons.add(
        _chip("View access", () {
          if (onRemoveAccess != null) onRemoveAccess!("view_access");
        }),
      );
    }

    if (manager.deleteAccess) {
      accessButtons.add(
        _chip("Delete access", () {
          if (onRemoveAccess != null) onRemoveAccess!("delete_access");
        }),
      );
    }
    if (manager.createAccess) {
      accessButtons.add(
        _chip("Create access", () {
          if (onRemoveAccess != null) onRemoveAccess!("create_access");
        }),
      );
    }
    // if (manager.c) accessButtons.add(_chip("Create access"));

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
                      manager.phone,
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

// ===================== BOTTOM SHEET (unchanged, only Save integrated) =====================
