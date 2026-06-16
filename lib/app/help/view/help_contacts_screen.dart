import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/local_storage.dart';
import 'package:seedsuser/app/help/contact_labels.dart';
import 'package:seedsuser/app/utils/network_config.dart';

/// Help → Contacts screen.
///
/// Shows the contacts that are marked active in the admin panel
/// (GET /api/farmer/contacts → only `status = 1` rows). Each contact can be
/// called or messaged on WhatsApp directly.
class HelpContactsScreen extends StatefulWidget {
  const HelpContactsScreen({super.key});

  @override
  State<HelpContactsScreen> createState() => _HelpContactsScreenState();
}

class _HelpContactsScreenState extends State<HelpContactsScreen> {
  bool _loading = true;
  String? _error;
  List<_Contact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

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
        final list = (body['contacts'] as List? ?? [])
            .map((e) => _Contact.fromJson(e as Map<String, dynamic>))
            .toList();
        // This screen is the Profile → Help action, so show the "Profile Help"
        // slot. Fall back to all active contacts if that slot isn't configured
        // so the screen is never empty.
        final preferred = list
            .where((c) => contactLabelMatches(c.label, ContactLabels.profileHelp))
            .toList();
        setState(() {
          _contacts = preferred.isNotEmpty ? preferred : list;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Unable to load contacts. Please try again.';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Something went wrong. Please check your connection.';
        _loading = false;
      });
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:${_digits(phone)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _whatsapp(String number) async {
    final uri = Uri.parse('https://wa.me/${_digits(number)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Keep digits only so `tel:` / `wa.me` links work regardless of how the
  /// admin entered the number (spaces, dashes, +).
  String _digits(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Help & Support',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _MessageState(
        icon: Icons.error_outline_rounded,
        message: _error!,
        actionLabel: 'Retry',
        onAction: _fetchContacts,
      );
    }

    if (_contacts.isEmpty) {
      return const _MessageState(
        icon: Icons.support_agent_rounded,
        message: 'No contacts available right now.',
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchContacts,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _contacts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _contactCard(_contacts[index]),
      ),
    );
  }

  Widget _contactCard(_Contact contact) {
    final hasPhone = contact.phone != null && contact.phone!.trim().isNotEmpty;
    final hasWhatsapp =
        contact.whatsapp != null && contact.whatsapp!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.headset_mic_rounded,
                color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (contact.label?.trim().isNotEmpty ?? false)
                      ? contact.label!
                      : 'Support',
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                if (hasPhone) ...[
                  const SizedBox(height: 4),
                  Text(
                    contact.phone!,
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hasPhone)
            _actionButton(
              icon: Icons.call,
              color: const Color(0xFF2196F3),
              onTap: () => _call(contact.phone!),
            ),
          if (hasWhatsapp) ...[
            const SizedBox(width: 8),
            _actionButton(
              icon: Icons.chat,
              color: const Color(0xFF25D366),
              onTap: () => _whatsapp(contact.whatsapp!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: AppColors.grey,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Contact {
  final int? id;
  final String? phone;
  final String? whatsapp;
  final String? label;

  _Contact({this.id, this.phone, this.whatsapp, this.label});

  factory _Contact.fromJson(Map<String, dynamic> json) {
    return _Contact(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}'),
      phone: json['phone']?.toString(),
      whatsapp: json['whatsapp']?.toString(),
      label: json['label']?.toString(),
    );
  }
}
