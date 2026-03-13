import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_button.dart';
import 'package:seedsuser/app/farm_management/manager/controller/manager_controller.dart';
import 'package:seedsuser/app/farm_management/manager/model/manager_list_model.dart'
    as mgr;
import 'package:seedsuser/app/farm_management/partner/controller/partener_controller.dart';
import 'package:seedsuser/app/farm_management/partner/model/partner_list_model.dart'
    as prt;

class AccessManagementScreen extends StatefulWidget {
  const AccessManagementScreen({super.key});

  @override
  State<AccessManagementScreen> createState() => _AccessManagementScreenState();
}

class _AccessManagementScreenState extends State<AccessManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ManagerController _managerController = Get.put(ManagerController());
  final PartnerController _partnerController = Get.put(PartnerController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _managerController.fetchManagers();
    _partnerController.fetchPartners();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Setup Access',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          InkWell(
            onTap: () => _onAddTap(),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: AppColors.primary, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'Add',
                    style: GoogleFonts.roboto(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: 'Managers'),
            Tab(text: 'Partners'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildManagersTab(),
          _buildPartnersTab(),
        ],
      ),
    );
  }

  void _onAddTap() {
    final initialRole = _tabController.index == 0 ? 'Manager' : 'Partner';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AddAccessFormScreen(
          initialRole: initialRole,
          onSaved: () {
            _managerController.fetchManagers();
            _partnerController.fetchPartners();
          },
        ),
      ),
    );
  }

  // ── Managers Tab ──
  Widget _buildManagersTab() {
    return Obx(() {
      if (_managerController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_managerController.managerList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                'No managers added yet',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        );
      }

      return Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _managerController.managerList.length,
            itemBuilder: (context, index) {
              final manager = _managerController.managerList[index];
              return _ManagerCard(
                manager: manager,
                onEdit: () => _showEditManager(manager),
                onRemoveAccess: (accessType) async {
                  bool isRemove = await _managerController.removeAccess(
                    id: manager.id.toString(),
                    accessType: accessType,
                  );
                  if (isRemove) _managerController.fetchManagers();
                },
                onDelete: () => _confirmDeleteManager(manager),
              );
            },
          ),
          if (_managerController.isAccessUpdating.value ||
              _managerController.isCreateLoading.value ||
              _managerController.isDeleting.value)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      );
    });
  }

  // ── Partners Tab ──
  Widget _buildPartnersTab() {
    return Obx(() {
      if (_partnerController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_partnerController.partnerList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                'No partners added yet',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        );
      }

      return Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _partnerController.partnerList.length,
            itemBuilder: (context, index) {
              final partner = _partnerController.partnerList[index];
              return _PartnerCard(
                partner: partner,
                onEdit: () => _showEditPartner(partner),
                onRemoveAccess: (accessType) async {
                  bool success = await _partnerController.removePartnerAccess(
                    id: partner.id.toString(),
                    accessType: accessType,
                  );
                  if (success) _partnerController.fetchPartners();
                },
                onDelete: () => _confirmDeletePartner(partner),
              );
            },
          ),
          if (_partnerController.isAccessUpdating.value ||
              _partnerController.isCreateLoading.value ||
              _partnerController.isDeleting.value)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      );
    });
  }

  // ── Edit actions ──
  void _showEditManager(mgr.Manager manager) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AddAccessFormScreen(
          initialRole: 'Manager',
          editManagerId: manager.id.toString(),
          initialName: manager.name,
          initialPhone: manager.phone,
          initialEdit: manager.editAccess,
          initialView: manager.viewAccess,
          initialDelete: manager.deleteAccess,
          initialCreate: manager.createAccess,
          onSaved: () {
            _managerController.fetchManagers();
            _partnerController.fetchPartners();
          },
        ),
      ),
    );
  }

  void _showEditPartner(prt.Partner partner) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AddAccessFormScreen(
          initialRole: 'Partner',
          editPartnerId: partner.id.toString(),
          initialName: partner.name,
          initialPhone: partner.phone,
          initialEdit: partner.editAccess,
          initialView: partner.viewAccess,
          initialDelete: false,
          initialCreate: false,
          onSaved: () {
            _managerController.fetchManagers();
            _partnerController.fetchPartners();
          },
        ),
      ),
    );
  }

  Future<void> _confirmDeleteManager(mgr.Manager manager) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this manager?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      bool deleted = await _managerController.deleteManager(
        id: manager.id.toString(),
      );
      if (deleted) _managerController.fetchManagers();
    }
  }

  Future<void> _confirmDeletePartner(prt.Partner partner) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this partner?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      bool deleted = await _partnerController.deletePartner(
        id: partner.id.toString(),
      );
      if (deleted) _partnerController.fetchPartners();
    }
  }
}


// ── Manager Card ──
class _ManagerCard extends StatelessWidget {
  final mgr.Manager manager;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(String accessType)? onRemoveAccess;

  const _ManagerCard({
    required this.manager,
    this.onEdit,
    this.onDelete,
    this.onRemoveAccess,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> accessButtons = [];
    if (manager.editAccess) {
      accessButtons.add(_chip("Edit access", () => onRemoveAccess?.call("edit_access")));
    }
    if (manager.viewAccess) {
      accessButtons.add(_chip("View access", () => onRemoveAccess?.call("view_access")));
    }
    if (manager.deleteAccess) {
      accessButtons.add(_chip("Delete access", () => onRemoveAccess?.call("delete_access")));
    }
    if (manager.createAccess) {
      accessButtons.add(_chip("Create access", () => onRemoveAccess?.call("create_access")));
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

// ── Partner Card ──
class _PartnerCard extends StatelessWidget {
  final prt.Partner partner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(String accessType)? onRemoveAccess;

  const _PartnerCard({
    required this.partner,
    this.onEdit,
    this.onDelete,
    this.onRemoveAccess,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> accessButtons = [];
    if (partner.editAccess) {
      accessButtons.add(_chip("Edit access", () => onRemoveAccess?.call("edit_access")));
    }
    if (partner.viewAccess) {
      accessButtons.add(_chip("View access", () => onRemoveAccess?.call("view_access")));
    }
    if (partner.readAccess) {
      accessButtons.add(_chip("Read access", () => onRemoveAccess?.call("read_access")));
    }
    if (partner.createAccess) {
      accessButtons.add(_chip("Create access", () => onRemoveAccess?.call("create_access")));
    }
    if (partner.deleteAccess) {
      accessButtons.add(_chip("Delete access", () => onRemoveAccess?.call("delete_access")));
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

// ── Unified Add/Edit Access Form Screen ──
class _AddAccessFormScreen extends StatefulWidget {
  final String initialRole;
  final String? editManagerId;
  final String? editPartnerId;
  final String? initialName;
  final String? initialPhone;
  final bool initialEdit;
  final bool initialView;
  final bool initialDelete;
  final bool initialCreate;
  final VoidCallback? onSaved;

  const _AddAccessFormScreen({
    required this.initialRole,
    this.editManagerId,
    this.editPartnerId,
    this.initialName,
    this.initialPhone,
    this.initialEdit = false,
    this.initialView = true,
    this.initialDelete = false,
    this.initialCreate = false,
    this.onSaved,
  });

  bool get isEditing => editManagerId != null || editPartnerId != null;

  @override
  State<_AddAccessFormScreen> createState() => _AddAccessFormScreenState();
}

class _AddAccessFormScreenState extends State<_AddAccessFormScreen> {
  final ManagerController _managerController = Get.find<ManagerController>();
  final PartnerController _partnerController = Get.find<PartnerController>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  late String _selectedRole;
  String _selectedDuration = '30 Days';
  late bool _canEdit;
  late bool _canView;
  late bool _canDelete;
  late bool _canCreate;
  bool _isSaving = false;

  final List<String> _roles = ['Manager', 'Partner'];
  final List<String> _durations = ['30 Days', '60 Days', '90 Days', '1 Year'];

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    _canEdit = widget.initialEdit;
    _canView = widget.initialView;
    _canDelete = widget.initialDelete;
    _canCreate = widget.initialCreate;
    if (widget.initialName != null) _nameController.text = widget.initialName!;
    if (widget.initialPhone != null) _phoneController.text = widget.initialPhone!;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter name and phone number')),
      );
      return;
    }

    setState(() => _isSaving = true);

    bool success = false;
    if (_selectedRole == 'Manager') {
      success = await _managerController.createManager(
        personName: name,
        phoneNumber: phone,
        canEdit: _canEdit,
        canView: _canView,
        canDelete: _canDelete,
        canCreate: _canCreate,
        id: widget.editManagerId,
      );
    } else {
      success = await _partnerController.createPartner(
        name: name,
        phone: phone,
        viewAccess: _canView,
        editAccess: _canEdit,
        id: widget.editPartnerId,
      );
    }

    setState(() => _isSaving = false);

    if (success) {
      widget.onSaved?.call();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isEditing ? 'Setup Access' : 'Setup Access',
          style: GoogleFonts.roboto(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
               Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    // ── Choose Role ──
                    _sectionLabel('Choose Role'),
                    const SizedBox(height: 8),
                    _dropdownField(
                      value: _selectedRole,
                      items: _roles,
                      onChanged: widget.isEditing
                          ? null
                          : (val) => setState(() => _selectedRole = val!),
                    ),
                    const SizedBox(height: 20),
          
                    // ── Duration ──
                    _sectionLabel('Duration'),
                    const SizedBox(height: 8),
                    _dropdownField(
                      value: _selectedDuration,
                      items: _durations,
                      onChanged: (val) => setState(() => _selectedDuration = val!),
                    ),
                    const SizedBox(height: 24),
          
                    // ── App Access ──
                    Text(
                      'App Access',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
          
                    _accessRow(
                      'Do you want to give ',
                      'edit access',
                      ' to this Person ?',
                      _canEdit,
                      (v) => setState(() => _canEdit = v),
                      labelColor: AppColors.primary,
                    ),
                    _accessRow(
                      'Do you want to give ',
                      'view access',
                      ' to this Person ?',
                      _canView,
                      (v) => setState(() => _canView = v),
                      labelColor: AppColors.primary,
                    ),
                    _accessRow(
                      'Do you want to give ',
                      'Delete access',
                      ' to this Person ?',
                      _canDelete,
                      (v) => setState(() => _canDelete = v),
                      labelColor: Colors.red,
                    ),
                    _accessRow(
                      'Do you want to give ',
                      'Create access',
                      ' to this Person ?',
                      _canCreate,
                      (v) => setState(() => _canCreate = v),
                      labelColor: AppColors.primary,
                    ),
                  ],
                ),
          
              const SizedBox(height: 30),
          
              // ── Generate QR Button ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomButton(
                  text: 'Generate QR',
                  isLoading: _isSaving,
                  onPressed: _onSave,
                  borderRadius: 30,
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.roboto(color: Colors.grey[400], fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  Widget _dropdownField({
    required String value,
    required List<String> items,
    required void Function(String?)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          style: GoogleFonts.roboto(fontSize: 14, color: Colors.black87),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _accessRow(
    String prefix,
    String highlight,
    String suffix,
    bool value,
    Function(bool) onChanged, {
    Color labelColor = Colors.blue,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: GoogleFonts.roboto(fontSize: 13, color: Colors.black87),
              children: [
                TextSpan(text: prefix),
                TextSpan(
                  text: highlight,
                  style: TextStyle(
                    color: labelColor,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(text: suffix),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: value,
                activeColor: AppColors.primary,
                onChanged: (v) => onChanged(v!),
              ),
              Text('Yes', style: GoogleFonts.roboto(fontSize: 14)),
              const SizedBox(width: 24),
              Radio<bool>(
                value: false,
                groupValue: value,
                activeColor: AppColors.primary,
                onChanged: (v) => onChanged(v!),
              ),
              Text('NO', style: GoogleFonts.roboto(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
