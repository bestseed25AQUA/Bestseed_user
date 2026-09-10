import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_button.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/farm_access_controller.dart';
import 'package:seedsuser/app/farm_management/farmer/model/farm_access_model.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/farm_shimmer.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/farmer_picker.dart';

/// Who currently holds access to one farm, and how to give or take it away.
///
/// Built entirely from `GET /farmer/farm/{id}/members` — the same table the
/// server consults when it decides whether someone may open a farm. It used to
/// be built from `/manager/managers` and `/partner/parteners`, a per-farm
/// address book of names that is not tied to any login and grants nothing, so
/// the two never agreed: a person who really held access could be absent from
/// this list, and a person typed in by hand appeared on it while the farm
/// stayed invisible to them.
///
/// Open to members, not just the owner. Anyone holding access may pass on what
/// they hold — the server caps the grant at the giver's own permissions.
class AccessManagementScreen extends StatefulWidget {
  /// Farm the access belongs to.
  final int farmId;

  /// What the logged-in farmer holds on that farm. Caps the permissions this
  /// screen may hand out.
  final FarmAccess access;

  /// The one role this screen is about.
  ///
  /// There used to be a Managers / Partners tab bar here. The farmer had
  /// already chosen a role to reach this screen, so the tabs let them wander
  /// into the other one and then be asked for the role a third time in the add
  /// form — where a different answer would silently contradict the tab they
  /// were looking at. One screen, one role.
  final FarmRole role;

  const AccessManagementScreen({
    super.key,
    required this.farmId,
    required this.role,
    this.access = const FarmAccess.ownerFallback(),
  });

  @override
  State<AccessManagementScreen> createState() => _AccessManagementScreenState();
}

class _AccessManagementScreenState extends State<AccessManagementScreen> {
  final FarmAccessController _access = Get.put(FarmAccessController());

  @override
  void initState() {
    super.initState();
    _refresh();
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
        // Explicit, because AppBar's default differs by platform — centred on
        // iOS, left-aligned on Android — and every other screen in this module
        // is left-aligned.
        centerTitle: false,
        // The back arrow already occupies a 56px slot; AppBar adds another
        // 16px before the title on top of it, which read as a gap.
        titleSpacing: 0,
        title: Text(
          'Setup Access for ${widget.role.label}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          // Hidden outright for someone who holds nothing to pass on — the
          // server would refuse the grant, so offering Add is a dead end.
          //
          // Hidden again while the list is empty: the empty state puts a full
          // Add button in the middle of the screen, and two of them competing
          // for the same tap is one too many.
          if (widget.access.canShareAccess)
            Obx(() {
              if (_access.isLoading.value || _people.isEmpty) {
                return const SizedBox.shrink();
              }

              return InkWell(
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
              );
            }),
        ],
      ),
      body: _buildList(),
    );
  }

  void _onAddTap() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AddAccessFormScreen(
          farmId: widget.farmId,
          callerAccess: widget.access,
          role: widget.role,
        ),
      ),
    );

    await _refresh();
  }

  /// Only this screen's role. A manager and a partner hold different things on
  /// the farm, and mixing them in one list was what made the tab bar necessary
  /// in the first place.
  List<FarmMember> get _people => _access.members
      .where((m) => m.isPartner == widget.role.isPartner)
      .toList();

  Widget _buildList() {
    return Obx(() {
      if (_access.isLoading.value) {
        return const ListTileShimmer();
      }

      final people = _people;

      if (people.isEmpty) {
        return RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
              Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                'No ${widget.role.pluralLabel.toLowerCase()} yet',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.access.canShareAccess
                    ? 'Give someone access to help run this farm.'
                    : 'Only people who can share access may add someone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  color: Colors.grey[400],
                ),
              ),

              // The button itself, rather than pointing at the one in the app
              // bar. An empty screen should carry the thing it is asking for.
              if (widget.access.canShareAccess) ...[
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _onAddTap,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text('Add ${widget.role.label}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      textStyle: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
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
          role: widget.role,
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
                  // Someone whose access was removed has nothing left to
                  // change or remove — the only thing left to do with them is
                  // let them back in. Saving from the same sheet restores
                  // them, because granting clears the revoke.
                  itemBuilder: (_) => member.isActive
                      ? const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Change access'),
                          ),
                          PopupMenuItem(
                            value: 'remove',
                            child: Text('Remove access'),
                          ),
                        ]
                      : const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Give access again'),
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
              'Added directly',
              if (member.grantedBy != null) 'by ${member.grantedBy}',
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
      child: Text(label, style: GoogleFonts.roboto(fontSize: 12, color: color)),
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

  /// The role being granted. Fixed by the screen that opened this form —
  /// there is no role picker any more, because the farmer already chose one
  /// to get here and a second answer could contradict the first.
  final FarmRole role;

  /// Set when changing an existing member's access rather than adding one.
  final FarmMember? editing;

  const _AddAccessFormScreen({
    required this.farmId,
    required this.callerAccess,
    required this.role,
    this.editing,
  });

  bool get isEditing => editing != null;

  @override
  State<_AddAccessFormScreen> createState() => _AddAccessFormScreenState();
}

class _AddAccessFormScreenState extends State<_AddAccessFormScreen> {
  final FarmAccessController _access = Get.put(FarmAccessController());

  /// People chosen to receive access directly.
  List<Map<String, dynamic>> _selectedPeople = [];

  late bool _canView;
  late bool _canEdit;
  late bool _canChangeTankStatus;
  late bool _canEditTotalFeed;
  late bool _canCreate;
  late bool _canDelete;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final existing = widget.editing?.permissions;
    // Capped from the start: pre-ticking something the giver cannot grant only
    // sets up a save that comes back changed.
    _canView = (existing?.view ?? true) && widget.callerAccess.canView;
    // On by default: a manager is brought in to run the farm day to day, and
    // correcting what a tank was fed is the core of that.
    _canEdit = (existing?.edit ?? true) && widget.callerAccess.canEdit;

    // Depends on the role. Marking a tank inactive harvests it — it closes
    // that tank's crop cycle — which is a partner's call to make, so they get
    // it with the role. A manager runs the farm day to day and is handed it
    // deliberately, the same way Total Feed is, so they start off without it.
    _canChangeTankStatus =
        (existing?.tankStatus ?? widget.role.isPartner) &&
        widget.callerAccess.canChangeTankStatus;

    // Off by default: the store figure drives the low-feed alerts and every
    // remaining-stock number on the farm, so it is handed over deliberately.
    _canEditTotalFeed =
        (existing?.totalFeed ?? false) && widget.callerAccess.canEditTotalFeed;

    _canCreate = (existing?.create ?? false) && widget.callerAccess.canCreate;
    _canDelete = (existing?.delete ?? false) && widget.callerAccess.canDelete;
  }

  bool get _grantsAnything =>
      _canView ||
      _canEdit ||
      _canChangeTankStatus ||
      _canEditTotalFeed ||
      _canCreate ||
      _canDelete;

  Future<void> _onSave() async {
    if (!_grantsAnything) {
      CustomToast.error('Give at least one kind of access');
      return;
    }

    if (widget.isEditing) {
      await _saveExisting();
      return;
    }

    // Access is always given directly to people picked by name — there is no
    // QR or PIN any more, for the owner or anyone else.
    if (_selectedPeople.isEmpty) {
      CustomToast.error('Choose at least one person to give access to');
      return;
    }

    await _grantDirect();
  }

  Future<void> _grantDirect({bool showToast = true}) async {
    final ids = _selectedPeople
        .map((p) => int.tryParse('${p['id']}') ?? 0)
        .where((id) => id > 0)
        .toList();

    // People added by a number nobody has registered yet. The server creates
    // their account, so the farm is waiting the first time they log in.
    final mobiles = _selectedPeople
        .where((p) => p['is_new'] == true)
        .map((p) => '${p['mobile']}')
        .where((m) => m.length == 10)
        .toList();

    if (ids.isEmpty && mobiles.isEmpty) return;

    setState(() => _isSaving = true);

    final ok = await _access.grantAccessTo(
      farmId: widget.farmId,
      farmerIds: ids,
      mobiles: mobiles,
      role: widget.role.apiValue,
      canView: _canView,
      canEdit: _canEdit,
      canChangeTankStatus: _canChangeTankStatus,
      canEditTotalFeed: _canEditTotalFeed,
      canCreate: _canCreate,
      canDelete: _canDelete,
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
      role: widget.role.apiValue,
      canView: _canView,
      canEdit: _canEdit,
      canChangeTankStatus: _canChangeTankStatus,
      canEditTotalFeed: _canEditTotalFeed,
      canCreate: _canCreate,
      canDelete: _canDelete,
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

              // The role, stated rather than asked.
              //
              // This was a Manager/Partner dropdown, which meant choosing the
              // role a second time after the farm sheet had already settled it
              // — and picking the other one here silently added the person to
              // a list the farmer was not looking at.
              _sectionLabel('Role'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.role.isPartner ? Icons.group : Icons.person,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.role.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Only when creating: editing changes one existing member's
              // permissions, so choosing a different set of people there would
              // have nothing to act on.
              if (!widget.isEditing) ...[
                FarmerPicker(
                  selected: _selectedPeople,
                  onChanged: (people) =>
                      setState(() => _selectedPeople = people),
                ),
                const SizedBox(height: 8),

                Text(
                  'Pick the people you want to give access to. They get it '
                  'straight away.',
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
              if (widget.callerAccess.canChangeTankStatus)
                _accessRow(
                  'Tank active / inactive access',
                  _canChangeTankStatus,
                  (v) => setState(() => _canChangeTankStatus = v),
                ),
              if (widget.callerAccess.canEditTotalFeed)
                _accessRow(
                  'Total feed access',
                  _canEditTotalFeed,
                  (v) => setState(() => _canEditTotalFeed = v),
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
                    text: widget.isEditing ? 'Save' : 'Give Access',
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
