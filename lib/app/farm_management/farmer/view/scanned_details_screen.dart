import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/farm_access_controller.dart';
import 'package:seedsuser/app/farm_management/farmer/model/farm_access_model.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/role_tab_bar.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/farm_shimmer.dart';

/// People who redeemed an access code for a farm, split by role.
///
/// "Remove" revokes the grant, which also strips the person's permissions
/// server-side, so access stops immediately rather than at expiry.
class ScannedDetailsScreen extends StatefulWidget {
  final int farmId;

  const ScannedDetailsScreen({super.key, required this.farmId});

  @override
  State<ScannedDetailsScreen> createState() => _ScannedDetailsScreenState();
}

class _ScannedDetailsScreenState extends State<ScannedDetailsScreen> {
  final _controller = Get.put(FarmAccessController());
  String _role = 'partner';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _controller.fetchGrantees(farmId: widget.farmId, role: _role);
  }

  void _onRoleChanged(String role) {
    setState(() => _role = role);
    _load();
  }

  Future<void> _confirmRemove(FarmGrantee grantee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove access'),
        content: Text(
          'Remove access for ${grantee.name ?? 'this person'}? '
          'They will lose access to this farm immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _controller.revokeAccess(grantee.grantId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'Scanned Details',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          RoleTabBar(selected: _role, onChanged: _onRoleChanged),
          Expanded(
            child: Obx(() {
              if (_controller.isLoading.value) {
                return const ListTileShimmer();
              }

              final people = _controller.grantees;

              if (people.isEmpty) return const _NoScannedPerson();

              return RefreshIndicator(
                onRefresh: () async => _load(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: people.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _GranteeCard(
                    grantee: people[i],
                    onRemove: () => _confirmRemove(people[i]),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _GranteeCard extends StatelessWidget {
  final FarmGrantee grantee;
  final VoidCallback onRemove;

  const _GranteeCard({required this.grantee, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final at = grantee.redeemedAt;
    final timeLabel = at == null ? '' : DateFormat('h:mm a, d MMM').format(at);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  grantee.farmName ?? '-',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              Text(
                timeLabel,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // The eye marks view access, matching the design's row icon.
              Icon(
                grantee.permissions.view
                    ? Icons.remove_red_eye_outlined
                    : Icons.visibility_off_outlined,
                color: grantee.permissions.view ? Colors.green : Colors.grey,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grantee.name ?? '-',
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    if (grantee.phone != null)
                      Text(
                        grantee.phone!,
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onRemove,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFFDEEEE),
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.close, size: 18),
                label: Text(
                  'Remove',
                  style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            grantee.daysRemaining > 0
                ? 'Expires in ${grantee.daysRemaining} days'
                : 'Expired',
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: grantee.daysRemaining > 0
                  ? Colors.grey.shade600
                  : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoScannedPerson extends StatelessWidget {
  const _NoScannedPerson();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner,
              size: 72,
              color: Colors.deepPurple.shade200,
            ),
            const SizedBox(height: 16),
            Text(
              'No scanned person found',
              style: GoogleFonts.roboto(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
