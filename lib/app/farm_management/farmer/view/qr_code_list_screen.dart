import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/farm_access_controller.dart';
import 'package:seedsuser/app/farm_management/farmer/model/farm_access_model.dart';
import 'package:seedsuser/app/farm_management/farmer/view/qr_generated_screen.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/role_tab_bar.dart';
import 'package:seedsuser/app/farm_management/farmer/widget/farm_shimmer.dart';

/// Every access code issued for a farm, split by role.
///
/// Tapping a row reopens its QR so it can be re-shared; the PIN is shown inline
/// because the farmer needs it to hand over alongside the code.
class QrCodeListScreen extends StatefulWidget {
  final int farmId;

  const QrCodeListScreen({super.key, required this.farmId});

  @override
  State<QrCodeListScreen> createState() => _QrCodeListScreenState();
}

class _QrCodeListScreenState extends State<QrCodeListScreen> {
  final _controller = Get.put(FarmAccessController());
  String _role = 'partner';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _controller.fetchGrants(farmId: widget.farmId, role: _role);
  }

  void _onRoleChanged(String role) {
    setState(() => _role = role);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'QR CODE',
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

              final grants = _controller.grants;

              if (grants.isEmpty) {
                return _EmptyState(role: _role);
              }

              return RefreshIndicator(
                onRefresh: () async => _load(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: grants.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _GrantCard(
                    grant: grants[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QrGeneratedScreen(grant: grants[i]),
                      ),
                    ),
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

class _GrantCard extends StatelessWidget {
  final FarmAccessGrant grant;
  final VoidCallback onTap;

  const _GrantCard({required this.grant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final created = grant.createdAt;
    final timeLabel =
        created == null ? '' : DateFormat('h:mm a, d MMM').format(created);

    // Expired or revoked codes stay visible but read as inactive.
    final isUsable = grant.status != 'expired' && grant.status != 'revoked';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        grant.isPartner ? 'Partner' : 'Manager',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isUsable ? Colors.black : Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        timeLabel,
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'PIN : ${grant.pin ?? '----'}',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Duration : ${grant.durationDays} Days',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(status: grant.status),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    switch (status) {
      case 'active':
        color = Colors.green;
        break;
      case 'pending':
        color = AppColors.primary;
        break;
      default:
        color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: GoogleFonts.roboto(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String role;

  const _EmptyState({required this.role});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_2, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No QR generated for ${role == 'partner' ? 'partners' : 'managers'} yet',
              textAlign: TextAlign.center,
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
