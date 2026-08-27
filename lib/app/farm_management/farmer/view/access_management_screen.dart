import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_button.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/farm_access_controller.dart';
import 'package:seedsuser/app/farm_management/farmer/model/farm_access_model.dart';
import 'package:seedsuser/app/farm_management/farmer/view/qr_generated_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/set_pin_sheet.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/farm_shimmer.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/farmer_picker.dart';

/// Who currently holds access to one farm, and how to give or take it away.
///
/// Built entirely from `GET /farmer/farm/{id}/members` — the same table the
/// server consults when it decides whether someone may open a farm. It used to
/// be built from `/manager/managers` and `/partner/parteners`, a per-farm
/// address book of names that is not tied to any login and grants nothing, so
/// the two never agreed: a person who scanned a QR held access but was absent
/// from this list, and a person typed in by hand appeared on it while the farm
/// stayed invisible to them.
///
/// Open to members, not just the owner. Anyone holding access may pass on what
/// they hold — the server caps the grant at the giver's own permissions.
class AccessManagementScreen extends StatefulWidget {
  /// Farm the access belongs to.
  final int farmId;

  /// What the logged-in farmer holds on that farm. Decides whether a QR can be
  /// issued (owner only) and caps the permissions this screen may hand out.
  final FarmAccess access;

  /// 0 = Managers, 1 = Partners.
  final int initialTab;

  const AccessManagementScreen({
    super.key,
    required this.farmId,
    this.access = const FarmAccess.ownerFallback(),
    this.initialTab = 0,
  });

  @override
  State<AccessManagementScreen> createState() => _AccessManagementScreenState();
}

class _AccessManagementScreenState extends State<AccessManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FarmAccessController _access = Get.put(FarmAccessController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _refresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() => _access.fetchMembers(farmId: widget.farmId);

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
          // Hidden outright for someone who holds nothing to pass on — the
          // server would refuse the grant, so offering Add is a dead end.
          if (widget.access.canShareAccess)
            InkWell(
              onTap: _onAddTap,
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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
        children: [_buildTab(isPartner: false), _buildTab(isPartner: true)],
      ),
    );
  }

  void _onAddTap() async {
    final role = _tabController.index == 0 ? 'Manager' : 'Partner';

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AddAccessFormScreen(
          farmId: widget.farmId,
          callerAccess: widget.access,
          initialRole: role,
        ),
      ),
    );

    await _refresh();
  }

  Widget _buildTab({required bool isPartner}) {
    return Obx(() {
      if (_access.isLoading.value) {
        return const ListTileShimmer();
      }

      final people = _access.members
          .where((m) => m.isPartner == isPartner)
          .toList();

      if (people.isEmpty) {
        return RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
              Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                isPartner ? 'No partners yet' : 'No managers yet',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.access.canShareAccess
                    ? 'Tap Add to give someone access to this farm.'
                    : 'Only people who can share access may add someone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        );
      }

      return Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: people.length,
              itemBuilder: (context, index) {
                final member = people[index];
                return _MemberCard(
                  member: member,
                  // Only offer the menu when there is something behind it. The
                  // server lets the owner touch anyone and lets a member touch
                  // only the people they admitted; it will still refuse, but
                  // there is no reason to show a control that must fail.
                  canManage: widget.access.canShareAccess,
                  onEdit: () => _editMember(member),
                  onRemove: () => _confirmRemove(member),
                );
              },
            ),
          ),
          if (_access.isSubmitting.value)
            Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      );
    });
  }

  Future<void> _editMember(FarmMember member) async {
    if (member.farmerId == null) {
      CustomToast.error('This person has no account to update');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AddAccessFormScreen(
          farmId: widget.farmId,
          callerAccess: widget.access,
          initialRole: member.isPartner ? 'Partner' : 'Manager',
          editing: member,
        ),
      ),
    );

    await _refresh();
  }

  Future<void> _confirmRemove(FarmMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove access?'),
        content: Text(
          '${member.name} will no longer be able to open this farm.',
          style: GoogleFonts.roboto(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (await _access.revokeMember(member.id)) await _refresh();
  }
}

// ── One person's access ──
class _MemberCard extends StatelessWidget {
  final FarmMember member;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _MemberCard({
    required this.member,
    required this.canManage,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (member.permissions.view) _chip('View access', AppColors.primary),
      if (member.permissions.edit) _chip('Edit access', AppColors.primary),
      if (member.permissions.create) _chip('Create access', AppColors.primary),
      if (member.permissions.delete) _chip('Delete access', Colors.red),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                      member.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (member.mobile != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        member.mobile!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _statusChip(member),
              if (canManage)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'remove') onRemove();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Change access'),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove access'),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),

          // How they got in, and from whom. Without this an owner had no way
          // to tell someone their manager let in from someone they admitted
          // themselves — which is exactly what decides who may remove them.
          Text(
            [
              member.via == 'qr' ? 'Joined by QR' : 'Added directly',
              if (member.grantedBy != null) 'by ${member.grantedBy}',
              if (member.expiresAt != null) '· ${_expiryLabel(member)}',
            ].join(' '),
            style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey[600]),
          ),

          if (chips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: chips),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              'No permissions left — this person can no longer open the farm.',
              style: GoogleFonts.roboto(fontSize: 12, color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }

  static String _expiryLabel(FarmMember member) {
    final expires = member.expiresAt;
    if (expires == null) return 'no expiry';

    final days = expires.difference(DateTime.now()).inDays;
    if (days < 0) return 'expired';
    if (days == 0) return 'expires today';
    return 'expires in $days day${days == 1 ? '' : 's'}';
  }

  Widget _statusChip(FarmMember member) {
    if (member.isActive) return const SizedBox.shrink();

    final revoked = member.status == 'revoked';
    final color = revoked ? Colors.red : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        revoked ? 'Removed' : 'Expired',
        style: GoogleFonts.roboto(fontSize: 11, color: color),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: GoogleFonts.roboto(fontSize: 12, color: color),
      ),
    );
  }
}

// ── Give or change access ──
class _AddAccessFormScreen extends StatefulWidget {
  final int farmId;

  /// What the person filling this form holds. Every toggle below is capped
  /// against it, matching the server, which silently drops any permission the
  /// giver does not hold and refuses the grant outright if that leaves nothing.
  final FarmAccess callerAccess;

  final String initialRole;

  /// Set when changing an existing member's access rather than adding one.
  final FarmMember? editing;

  const _AddAccessFormScreen({
    required this.farmId,
    required this.callerAccess,
    required this.initialRole,
    this.editing,
  });

  bool get isEditing => editing != null;

  @override
  State<_AddAccessFormScreen> createState() => _AddAccessFormScreenState();
}

class _AddAccessFormScreenState extends State<_AddAccessFormScreen> {
  final FarmAccessController _access = Get.put(FarmAccessController());

  late String _selectedRole;
  late String _selectedDuration;

  /// People chosen to receive access directly.
  List<Map<String, dynamic>> _selectedPeople = [];

  late bool _canView;
  late bool _canEdit;
  late bool _canCreate;
  late bool _canDelete;

  bool _isSaving = false;

  final List<String> _roles = ['Manager', 'Partner'];
  final List<String> _durations = ['30 Days', '60 Days', '90 Days', '1 Year'];

  /// Only the owner may mint a QR — `/farm/{id}/access/generate` checks
  /// ownership, not a permission flag, because the code is the farm's key.
  /// A manager passing access on therefore grants people directly instead.
  bool get _canIssueQr => widget.callerAccess.canManageAccessCodes;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    _selectedDuration = _durations.first;

    final existing = widget.editing?.permissions;
    // Capped from the start: pre-ticking something the giver cannot grant only
    // sets up a save that comes back changed.
    _canView = (existing?.view ?? true) && widget.callerAccess.canView;
    _canEdit = (existing?.edit ?? false) && widget.callerAccess.canEdit;
    _canCreate = (existing?.create ?? false) && widget.callerAccess.canCreate;
    _canDelete = (existing?.delete ?? false) && widget.callerAccess.canDelete;
  }

  /// '30 Days' → 30, '1 Year' → 365.
  int get _durationDays {
    if (_selectedDuration.toLowerCase().contains('year')) return 365;
    return int.tryParse(_selectedDuration.split(' ').first) ?? 30;
  }

  /// Whole days left on the member being edited, so changing their permissions
  /// does not silently reset their expiry to "never".
  int? get _remainingDays {
    final expires = widget.editing?.expiresAt;
    if (expires == null) return null;

    final days = expires.difference(DateTime.now()).inDays;
    return days > 0 ? days : 1;
  }

  bool get _grantsAnything => _canView || _canEdit || _canCreate || _canDelete;

  Future<void> _onSave() async {
    if (!_grantsAnything) {
      CustomToast.error('Give at least one kind of access');
      return;
    }

    if (widget.isEditing) {
      await _saveExisting();
      return;
    }

    // No QR to issue: grant the picked people directly. This is the path a
    // manager or partner takes when passing on access.
    if (!_canIssueQr) {
      if (_selectedPeople.isEmpty) {
        CustomToast.error('Choose at least one person to give access to');
        return;
      }
      await _grantDirect(grantId: null);
      return;
    }

    await _generateQr();
  }

  Future<void> _generateQr() async {
    await showPinSheet(
      context,
      title: 'Set a PIN',
      subtitle:
          'Enter a PIN to keep your access safe from misuse and '
          'ensure only trusted members can use it.',
      confirmLabel: 'Confirm',
      onConfirm: (pin) async {
        final grant = await _access.generateAccess(
          farmId: widget.farmId,
          role: _selectedRole.toLowerCase(),
          durationDays: _durationDays,
          pin: pin,
          canView: _canView,
          canEdit: _canEdit,
          canCreate: _canCreate,
          canDelete: _canDelete,
        );

        if (grant == null) return false;

        // Anyone picked above gets access immediately, tied to this code so
        // revoking the QR revokes them too. Scanning still works as before for
        // anyone not on the list.
        if (_selectedPeople.isNotEmpty) {
          await _grantDirect(grantId: grant.id, showToast: false);
        }

        if (!mounted) return true;

        // Close the PIN sheet, then swap this form for the QR result so
        // backing out lands on the access list rather than the form again.
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => QrGeneratedScreen(grant: grant)),
        );
        return true;
      },
    );
  }

  Future<void> _grantDirect({int? grantId, bool showToast = true}) async {
    final ids = _selectedPeople
        .map((p) => int.tryParse('${p['id']}') ?? 0)
        .where((id) => id > 0)
        .toList();

    if (ids.isEmpty) return;

    setState(() => _isSaving = true);

    final ok = await _access.grantAccessTo(
      farmId: widget.farmId,
      farmerIds: ids,
      role: _selectedRole.toLowerCase(),
      canView: _canView,
      canEdit: _canEdit,
      canCreate: _canCreate,
      canDelete: _canDelete,
      durationDays: _durationDays,
      grantId: grantId,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok && showToast) {
      CustomToast.success('Access given');
      Navigator.pop(context);
    }
  }

  /// Change an existing member's permissions.
  ///
  /// The same members endpoint: it upserts on (farm, farmer), so re-sending a
  /// person with different flags rewrites their access in place. Their
  /// remaining days are sent back unchanged so an edit does not quietly turn a
  /// 30-day grant into a permanent one.
  Future<void> _saveExisting() async {
    final farmerId = widget.editing?.farmerId;
    if (farmerId == null) return;

    setState(() => _isSaving = true);

    final ok = await _access.grantAccessTo(
      farmId: widget.farmId,
      farmerIds: [farmerId],
      role: _selectedRole.toLowerCase(),
      canView: _canView,
      canEdit: _canEdit,
      canCreate: _canCreate,
      canDelete: _canDelete,
      durationDays: _remainingDays,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      CustomToast.success('Access updated');
      Navigator.pop(context);
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
          widget.isEditing ? 'Change Access' : 'Setup Access',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isEditing) ...[
                const SizedBox(height: 4),
                Text(
                  widget.editing!.name,
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.editing!.mobile != null)
                  Text(
                    widget.editing!.mobile!,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
              ],

              const SizedBox(height: 12),
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

              // Editing keeps whatever is left of the existing grant, so a
              // duration picker here would be a lie.
              if (!widget.isEditing) ...[
                _sectionLabel('Duration'),
                const SizedBox(height: 8),
                _dropdownField(
                  value: _selectedDuration,
                  items: _durations,
                  onChanged: (val) =>
                      setState(() => _selectedDuration = val!),
                ),
                const SizedBox(height: 24),

                FarmerPicker(
                  selected: _selectedPeople,
                  onChanged: (people) =>
                      setState(() => _selectedPeople = people),
                ),
                const SizedBox(height: 8),

                Text(
                  _canIssueQr
                      ? 'Anyone picked here gets access straight away. Leave it '
                            'empty and only the QR decides who gets in.'
                      : 'Pick the people you want to give access to. Only the '
                            'farm owner can issue a QR code.',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              Text(
                'App Access',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!widget.callerAccess.isOwner) ...[
                const SizedBox(height: 4),
                Text(
                  'You can only pass on the access you hold yourself.',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Each row is hidden when the giver does not hold that ability —
              // the server would strip it anyway, and a toggle whose answer is
              // ignored is worse than no toggle.
              if (widget.callerAccess.canView)
                _accessRow(
                  'view access',
                  _canView,
                  (v) => setState(() => _canView = v),
                ),
              if (widget.callerAccess.canEdit)
                _accessRow(
                  'edit access',
                  _canEdit,
                  (v) => setState(() => _canEdit = v),
                ),
              if (widget.callerAccess.canCreate)
                _accessRow(
                  'Create access',
                  _canCreate,
                  (v) => setState(() => _canCreate = v),
                ),
              if (widget.callerAccess.canDelete)
                _accessRow(
                  'Delete access',
                  _canDelete,
                  (v) => setState(() => _canDelete = v),
                  labelColor: Colors.red,
                ),

              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(
                  () => CustomButton(
                    text: widget.isEditing
                        ? 'Save'
                        : (_canIssueQr ? 'Generate QR' : 'Give Access'),
                    isLoading: _isSaving || _access.isSubmitting.value,
                    onPressed: _onSave,
                    borderRadius: 30,
                  ),
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
    String highlight,
    bool value,
    Function(bool) onChanged, {
    Color labelColor = AppColors.primary,
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
                const TextSpan(text: 'Do you want to give '),
                TextSpan(
                  text: highlight,
                  style: TextStyle(
                    color: labelColor,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const TextSpan(text: ' to this Person ?'),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Radio<bool>(
                value: true,
                // ignore: deprecated_member_use
                groupValue: value,
                activeColor: AppColors.primary,
                // ignore: deprecated_member_use
                onChanged: (v) => onChanged(v!),
              ),
              Text('Yes', style: GoogleFonts.roboto(fontSize: 14)),
              const SizedBox(width: 24),
              Radio<bool>(
                value: false,
                // ignore: deprecated_member_use
                groupValue: value,
                activeColor: AppColors.primary,
                // ignore: deprecated_member_use
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
