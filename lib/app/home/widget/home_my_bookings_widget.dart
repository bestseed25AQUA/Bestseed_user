import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:seedsuser/app/booking/controller/my_booking_controller.dart';
import 'package:seedsuser/app/booking/view/booking_detail_screen.dart';
import 'package:seedsuser/app/booking/view/booking_screen.dart';
import 'package:seedsuser/app/common/animated_view_custom.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/model/my_booking_model.dart';

/// Compact "My Bookings" section for the Home screen. Renders the two most
/// recent bookings and a "View all" link that opens [MyBookingScreen]. When the
/// user has no bookings the whole section collapses to `SizedBox.shrink()` so
/// the home layout doesn't show an empty card.
class HomeMyBookingsWidget extends StatelessWidget {
  const HomeMyBookingsWidget({super.key});

  static const int _previewCount = 1;

  /// Delivered (5) and Cancelled (6) are terminal statuses — the farmer
  /// can't take any further action on them, so they're excluded from the
  /// Home preview. They still appear in the full My Bookings screen.
  static bool _isTerminal(dynamic status) {
    if (status is Map && status['value'] is int) {
      final value = status['value'] as int;
      return value == 5 || value == 6;
    }
    return false;
  }

  /// Priority ranking used to pick which single booking the Home card
  /// surfaces when the farmer has multiple active ones. Later stages of a
  /// delivery are more actionable than earlier stages, so we rank:
  ///
  ///   4 (In Journey)      → 4  ← most urgent
  ///   3 (Driver Assigned) → 3
  ///   2 (Confirmed)       → 2
  ///   1 (Pending)         → 1  ← least urgent
  ///
  /// Unknown / terminal statuses return -1 (already filtered upstream, this
  /// is just a safety net).
  static int _statusPriority(dynamic status) {
    if (status is Map && status['value'] is int) {
      final v = status['value'] as int;
      if (v >= 1 && v <= 4) return v;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MyBookingController());

    return Obx(() {
      // Only preview ACTIVE bookings on Home. Delivered (status 5) and
      // Cancelled (status 6) are terminal — nothing for the farmer to act on,
      // so they clutter the home card. "View all" still shows them in the
      // full My Bookings screen.
      final active = controller.bookingList
          .where((b) => !_isTerminal(b.status))
          .toList();
      if (active.isEmpty) return const SizedBox.shrink();

      // Pick the highest-priority booking to surface on Home. If several
      // bookings share the same status we keep the newest one — the backend
      // returns newest-first, so we iterate from index 0 and use `>` (not
      // `>=`) so ties don't overwrite the first-seen (newest) entry.
      BookingData best = active.first;
      int bestPriority = _statusPriority(best.status);
      for (int i = 1; i < active.length; i++) {
        final p = _statusPriority(active[i].status);
        if (p > bestPriority) {
          best = active[i];
          bestPriority = p;
        }
      }
      final preview = <BookingData>[best].take(_previewCount).toList();

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context),
            const SizedBox(height: 10),
            ...List.generate(preview.length, (i) {
              final b = preview[i];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: i == preview.length - 1 ? 0 : 8,
                ),
                child: _BookingPreviewCard(booking: b),
              );
            }),
          ],
        ),
      );
    });
  }

  Widget _header(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'My Bookings',
          style: GoogleFonts.roboto(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        AnimatedViewAllBadge(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyBookingScreen()),
          ),
        ),
      ],
    );
  }
}

class _BookingPreviewCard extends StatelessWidget {
  final BookingData booking;

  const _BookingPreviewCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final statusLabel = _statusLabel(booking.status);
    final statusColor = _statusColor(booking.status);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Get.to(
        () => MyBookingScreen(),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: hatchery name + status chip
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.hatcheryName.isEmpty
                        ? 'Hatchery'
                        : booking.hatcheryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (statusLabel.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            // Numeric booking ID — matches the "#1010" style shown in the
            // admin panel. The long booking_uid ("OD-BS-TS-…") is available
            // on the detail screen for anyone who needs it.
            if (booking.bookingId > 0)
              Text(
                '#${booking.bookingId}',
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            const SizedBox(height: 6),
            // Meta row: packing date + drop location
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 12,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(booking.packingDate),
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (booking.droppingLocation.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Icon(
                    Icons.location_on_outlined,
                    size: 12,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      booking.droppingLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(dynamic status) {
    if (status is Map && status['label'] is String) {
      return status['label'] as String;
    }
    return '';
  }

  Color _statusColor(dynamic status) {
    final value = (status is Map && status['value'] is int)
        ? status['value'] as int
        : 0;
    switch (value) {
      case 1:
        return const Color(0xFFF59E0B); // Pending — amber
      case 2:
        return const Color(0xFF6F42C1); // Confirmed — purple
      case 3:
        return const Color(0xFF20C997); // Driver Assigned — teal
      case 4:
        return AppColors.primary; // In Journey — brand
      case 5:
        return const Color(0xFF28A745); // Delivered — green
      case 6:
        return const Color(0xFFDC3545); // Cancelled — red
      default:
        return Colors.grey.shade600;
    }
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '--';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('d MMM, yyyy').format(parsed);
  }
}
