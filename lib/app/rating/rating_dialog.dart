import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/local_storage.dart';
import 'package:seedsuser/app/rating/pending_rating.dart';
import 'package:seedsuser/app/utils/network_config.dart';

/// Rating + feedback popup shown once after a booking is delivered.
///
/// Pops `true` when the rating was submitted, and `null`/`false` when the user
/// closed/cancelled it — the caller uses that to tell the server not to ask
/// again. Submitting is optional (the close X dismisses without rating).
class RatingDialog extends StatefulWidget {
  final PendingRating pending;

  const RatingDialog({super.key, required this.pending});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  static const Color _primaryDark = Color(0xFF005A92);
  static const List<String> _ratingLabels = [
    '',
    'Poor',
    'Fair',
    'Good',
    'Very Good',
    'Excellent',
  ];

  int _rating = 0;
  final TextEditingController _messageController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1) {
      setState(() => _error = 'Please tap a star to rate.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final token = await AuthLocalStorage.getToken();
      final response = await http.post(
        Uri.parse('${NetworkConfig.baseURL}/farmer/rate-booking'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'booking_id': widget.pending.id,
          'rating': _rating,
          'message': _messageController.text.trim(),
        }),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['status'] == true) {
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(body['message']?.toString() ??
                  'Thank you for your feedback!'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } else {
        setState(() {
          _error = body['message']?.toString() ??
              'Could not submit. Please try again.';
          _submitting = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pending;
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _bookingDetailCard(p),
                  const SizedBox(height: 18),

                  // Rating label (changes with the chosen rating)
                  Text(
                    _rating == 0
                        ? 'Tap a star to rate'
                        : _ratingLabels[_rating],
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _rating == 0
                          ? Colors.grey.shade500
                          : const Color(0xFFF5A623),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      return IconButton(
                        onPressed: _submitting
                            ? null
                            : () => setState(() {
                                  _rating = star;
                                  _error = null;
                                }),
                        icon: Icon(
                          star <= _rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: const Color(0xFFF5A623),
                          size: 40,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        constraints: const BoxConstraints(),
                        splashRadius: 24,
                      );
                    }),
                  ),
                  const SizedBox(height: 14),

                  // Comment
                  TextField(
                    controller: _messageController,
                    enabled: !_submitting,
                    maxLines: 3,
                    maxLength: 500,
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Write a comment (optional)',
                      hintStyle: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.grey.shade400),
                      contentPadding: const EdgeInsets.all(12),
                      filled: true,
                      fillColor: const Color(0xFFFAFBFC),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.primary, width: 1.4),
                      ),
                      counterText: '',
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.error_outline,
                            size: 15, color: Colors.red.shade400),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _error!,
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.red.shade400),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Submit Rating',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                              ),
                            )
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Gradient header with the delivered icon, title and close button ──
  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, _primaryDark],
        ),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 34),
              ),
              const SizedBox(height: 12),
              Text(
                'Rate your delivery',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Your order has been delivered',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          Positioned(
            top: -8,
            right: -8,
            child: IconButton(
              onPressed: _submitting
                  ? null
                  : () {
                      debugPrint(
                          '⭐[RATING] close (X) tapped for booking ${widget.pending.id}');
                      Navigator.of(context).pop();
                    },
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              iconSize: 22,
              splashRadius: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ── Booking summary card ──
  Widget _bookingDetailCard(PendingRating p) {
    final title = (p.hatcheryName?.trim().isNotEmpty ?? false)
        ? p.hatcheryName!
        : 'Your booking';

    final quantity = (p.noOfPieces?.trim().isNotEmpty ?? false)
        ? '${p.noOfPieces}${(p.unit?.trim().isNotEmpty ?? false) ? ' ${p.unit}' : ''}'
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAEEF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
              if (p.bookingUid?.trim().isNotEmpty ?? false)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#${p.bookingUid}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if ((p.categoryName?.trim().isNotEmpty ?? false) ||
              quantity != null ||
              (p.driverName?.trim().isNotEmpty ?? false)) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFEAEEF2)),
            const SizedBox(height: 10),
          ],
          if (p.categoryName?.trim().isNotEmpty ?? false)
            _detailRow(Icons.category_outlined, p.categoryName!),
          if (quantity != null)
            _detailRow(Icons.inventory_2_outlined, quantity),
          if (p.driverName?.trim().isNotEmpty ?? false)
            _detailRow(Icons.local_shipping_outlined, 'Driver: ${p.driverName}'),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
