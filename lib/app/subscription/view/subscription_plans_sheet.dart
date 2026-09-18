import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/subscription/model/subscription_models.dart';
import 'package:seedsuser/app/subscription/view/subscription_contact_screen.dart';

/// The packages on offer, shown when a farmer has used up their free farms.
///
/// Nothing is bought here. Picking a package opens a page with the helpline's
/// number on it, because payment is taken over the phone by the admin who then
/// records the subscription in the panel.
Future<void> showSubscriptionPlansSheet(
  BuildContext context,
  SubscriptionStatus status,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _SubscriptionPlansSheet(status: status),
  );
}

class _SubscriptionPlansSheet extends StatelessWidget {
  final SubscriptionStatus status;

  const _SubscriptionPlansSheet({required this.status});

  /// The plan with the lowest cost per month, badged as the best value.
  ///
  /// Worked out rather than hardcoded so it stays right if the prices change
  /// on the server. Null when no plan reports a per-month figure.
  String? get _bestValueKey {
    final rated = status.plans.where((p) => p.perMonth != null).toList();
    if (rated.length < 2) return null;

    rated.sort((a, b) => a.perMonth!.compareTo(b.perMonth!));
    return rated.first.key;
  }

  @override
  Widget build(BuildContext context) {
    final bestValue = _bestValueKey;

    return SafeArea(
      child: ConstrainedBox(
        // Never taller than most of the screen, and scrollable inside that, so
        // the sheet still works on a short phone in landscape.
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    size: 44,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Add More Farms',
                    style: GoogleFonts.poppins(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    // The server's own words, so the reason is exact: "you get
                    // 2 for free" reads very differently from "yours ran out
                    // on the 3rd", and only the server knows which it is.
                    status.message ??
                        'Subscribe to create more farms. Your existing farms '
                            'are not affected.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      height: 1.45,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Flexible(
              child: status.plans.isEmpty
                  ? _noPlans()
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: status.plans.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final plan = status.plans[index];

                        return _PlanCard(
                          plan: plan,
                          isBestValue: plan.key == bestValue,
                          onTap: () {
                            // Close the sheet first so the back button from
                            // the contact page returns to the farm list, not
                            // to a sheet the farmer has finished with.
                            Navigator.of(context).pop();

                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SubscriptionContactScreen(
                                  plan: plan,
                                  contact: status.contact,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Text(
                'Pick a package to see the number to call. Payment is taken '
                'over the phone — there is nothing to pay inside the app.',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 11.5,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shown when the server sent no catalogue — a misconfiguration, but the
  /// farmer still needs a way forward rather than an empty box.
  Widget _noPlans() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Text(
        'Packages are not available right now. Please contact support.',
        textAlign: TextAlign.center,
        style: GoogleFonts.roboto(fontSize: 13, color: Colors.grey.shade600),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isBestValue;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.isBestValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isBestValue
                ? AppColors.primary.withValues(alpha: 0.06)
                : const Color(0xFFF6F8FA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isBestValue
                  ? AppColors.primary.withValues(alpha: 0.55)
                  : Colors.grey.shade200,
              width: isBestValue ? 1.6 : 1,
            ),
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
                          plan.label,
                          style: GoogleFonts.poppins(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isBestValue) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'BEST VALUE',
                              style: GoogleFonts.roboto(
                                fontSize: 9,
                                letterSpacing: 0.4,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Unlimited farms for '
                      '${plan.months} month${plan.months == 1 ? '' : 's'}',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    plan.priceLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
