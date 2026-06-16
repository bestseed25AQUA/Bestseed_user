import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/local_storage.dart';
import 'package:seedsuser/app/help/contact_labels.dart';
import 'package:seedsuser/app/utils/network_config.dart';

/// A support contact configured (and marked active) in the admin panel.
class HelpContact {
  final int? id;
  final String? phone;
  final String? whatsapp;
  final String? label;

  HelpContact({this.id, this.phone, this.whatsapp, this.label});

  factory HelpContact.fromJson(Map<String, dynamic> json) {
    return HelpContact(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      phone: json['phone']?.toString(),
      whatsapp: json['whatsapp']?.toString(),
      label: json['label']?.toString(),
    );
  }

  bool get hasPhone => (phone?.trim().isNotEmpty ?? false);
  bool get hasWhatsapp => (whatsapp?.trim().isNotEmpty ?? false);
}

/// Fetches the active contacts from the admin panel
/// (GET /api/farmer/contacts → only `status = 1` rows).
/// Returns an empty list on any failure so callers can fall back gracefully.
Future<List<HelpContact>> fetchActiveHelpContacts() async {
  try {
    final token = await AuthLocalStorage.getToken();
    final response = await http.get(
      Uri.parse('${NetworkConfig.baseURL}/farmer/contacts'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return (body['contacts'] as List? ?? [])
          .map((e) => HelpContact.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  } catch (_) {
    // Swallow — caller decides how to handle an empty result.
  }
  return [];
}

/// Keep digits only so `tel:` / `wa.me` links work regardless of how the
/// admin entered the number (spaces, dashes, +).
String helpContactDigits(String value) =>
    value.replaceAll(RegExp(r'[^0-9]'), '');

Future<void> launchHelpCall(String phone) async {
  final uri = Uri.parse('tel:${helpContactDigits(phone)}');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

Future<void> launchHelpWhatsApp(String number) async {
  final uri = Uri.parse('https://wa.me/${helpContactDigits(number)}');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Shows a bottom sheet listing the active admin contacts with call /
/// WhatsApp actions. [fallbackPhone] (e.g. the vendor's number) is shown when
/// the admin hasn't configured any active contacts.
Future<void> showHelpContactsSheet(
  BuildContext context, {
  String? fallbackPhone,
  String? preferredLabel,
}) async {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return FutureBuilder<List<HelpContact>>(
        future: fetchActiveHelpContacts(),
        builder: (context, snapshot) {
          final loading =
              snapshot.connectionState == ConnectionState.waiting;
          var contacts = snapshot.data ?? [];

          // Prefer the slot this screen asked for (e.g. "Booking Help"), but
          // fall back to all active contacts if that slot isn't configured so
          // the sheet is never empty.
          if (preferredLabel != null) {
            final preferred = contacts
                .where((c) => contactLabelMatches(c.label, preferredLabel))
                .toList();
            if (preferred.isNotEmpty) contacts = preferred;
          }

          // Fall back to the vendor number if admin has no active contacts.
          if (!loading &&
              contacts.isEmpty &&
              (fallbackPhone?.trim().isNotEmpty ?? false)) {
            contacts = [HelpContact(label: 'Support', phone: fallbackPhone)];
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Need Help?',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Reach us on any of the numbers below',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (contacts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No contacts available right now.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    )
                  else
                    ...contacts.map((c) => _sheetContactRow(c)),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _sheetContactRow(HelpContact contact) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F7FA),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.support_agent_rounded,
              color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (contact.label?.trim().isNotEmpty ?? false)
                    ? contact.label!
                    : 'Support',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (contact.hasPhone)
                Text(
                  contact.phone!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
        if (contact.hasPhone)
          _sheetActionButton(
            icon: Icons.call_rounded,
            color: const Color(0xFF2196F3),
            onTap: () => launchHelpCall(contact.phone!),
          ),
        if (contact.hasWhatsapp) ...[
          const SizedBox(width: 8),
          _sheetActionButton(
            icon: Icons.chat,
            color: const Color(0xFF25D366),
            onTap: () => launchHelpWhatsApp(contact.whatsapp!),
          ),
        ],
      ],
    ),
  );
}

Widget _sheetActionButton({
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(22),
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    ),
  );
}
