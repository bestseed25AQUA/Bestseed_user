import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/help/contact_labels.dart';
import 'package:seedsuser/app/help/help_contact_service.dart';
import 'package:seedsuser/app/subscription/model/subscription_models.dart';

/// What to do after picking a package: ring the helpline.
///
/// The farmer pays the person who answers, and that person records the
/// subscription in the admin panel. So this screen's whole job is to show the
/// chosen package clearly enough to say out loud, and put a working Call
/// button under it.
class SubscriptionContactScreen extends StatefulWidget {
  final SubscriptionPlan plan;

  /// Resolved server-side alongside the plans. Null only when the admin panel
  /// has no active contact at all, in which case we fetch as a last resort.
  final SubscriptionContact? contact;

  const SubscriptionContactScreen({
    super.key,
    required this.plan,
    this.contact,
  });

  @override
  State<SubscriptionContactScreen> createState() =>
      _SubscriptionContactScreenState();
}

class _SubscriptionContactScreenState extends State<SubscriptionContactScreen> {
  SubscriptionContact? _contact;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _contact = widget.contact;

    // The status call normally carries the number, so this is a fallback for
    // an older server or a response that arrived without one. Fetching here
    // rather than showing "no number" keeps the sale alive.
    if (_contact == null || !_contact!.hasPhone) {
      _loadContact();
    }
  }

  Future<void> _loadContact() async {
    setState(() => _loading = true);

    final contacts = await fetchActiveHelpContacts();

    if (!mounted) return;

    HelpContact? picked;
    if (contacts.isNotEmpty) {
      picked = contacts.firstWhere(
        (c) => contactLabelMatches(c.label, ContactLabels.farmManagementHelp),
        orElse: () => contacts.first,
      );
    }

    setState(() {
      _loading = false;
      if (picked != null) {
        _contact = SubscriptionContact(
          phone: picked.phone,
          whatsapp: picked.whatsapp,
          label: picked.label,
        );
      }
    });
  }

  String get _phone => _contact?.phone?.trim() ?? '';

  /// What the farmer should say on the call, and what they can paste into
  /// WhatsApp. Naming the package avoids the commonest support problem: a
  /// farmer who says "the big one" and is recorded on the wrong plan.
  String get _enquiry =>
      'Hello, I would like to subscribe to the '
      '${widget.plan.label} Farm Management package (${widget.plan.priceLabel}).';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
        title: Text(
          'Subscribe',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _planSummary(),
              const SizedBox(height: 28),
              _steps(),
              const SizedBox(height: 28),
              _numberBlock(),
              const SizedBox(height: 20),
              _actions(),
              const SizedBox(height: 22),
              Text(
                'Your subscription starts as soon as our team records your '
                'payment. Farms you already have are never affected.',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 11.5,
                  color: Colors.grey.shade600,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _planSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            'You selected',
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.plan.label,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.plan.priceLabel,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Unlimited farms for '
            '${widget.plan.months} month${widget.plan.months == 1 ? '' : 's'}',
            style: GoogleFonts.roboto(
              fontSize: 12.5,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _steps() {
    const steps = [
      'Call the number below.',
      'Tell our team which package you want.',
      'Pay over the phone as our team guides you.',
      'Your farms unlock as soon as it is recorded.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How to subscribe',
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...List.generate(steps.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      steps[index],
                      style: GoogleFonts.roboto(
                        fontSize: 13.5,
                        height: 1.35,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _numberBlock() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: SizedBox(
            height: 26,
            width: 26,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      );
    }

    if (_phone.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Text(
          'No helpline number is set up right now. Please try again shortly.',
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(
            fontSize: 13,
            color: Colors.orange.shade900,
          ),
        ),
      );
    }

    return Column(
      children: [
        Text(
          'Farm Management Helpline',
          style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 6),
        // Long-press to copy: a farmer often wants to ring from another
        // handset, or save the number first.
        InkWell(
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: _phone));
            CustomToast.success('Number copied');
          },
          child: Text(
            _phone,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _actions() {
    final hasPhone = _phone.isNotEmpty;
    final hasWhatsapp = _contact?.hasWhatsapp ?? false;

    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            // Disabled rather than hidden when there is no number, so the
            // layout does not jump once the fallback fetch lands.
            onPressed: hasPhone ? () => launchHelpCall(_phone) : null,
            icon: const Icon(Icons.call_rounded, color: Colors.white),
            label: Text(
              'Call Now',
              style: GoogleFonts.poppins(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (hasWhatsapp) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => launchHelpWhatsAppWithMessage(
                _contact!.whatsapp!,
                _enquiry,
              ),
              icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
              label: Text(
                'Message on WhatsApp',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF128C7E),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF25D366), width: 1.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
