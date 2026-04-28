import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_shimmer_widget.dart';
import 'package:seedsuser/app/seed_price/controller/seed_wanted_controller.dart';
import 'package:seedsuser/app/seed_price/model/seed_wanted_model.dart';
import 'package:url_launcher/url_launcher.dart';

class SeedWantedScreen extends StatelessWidget {
  const SeedWantedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SeedWantedController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Wanted Stock',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          bottom: TabBar(
            onTap: (index) {
              final species = index == 0 ? 'shrimp' : 'fish';
              controller.fetchListings(species: species);
            },
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            labelStyle: GoogleFonts.roboto(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.roboto(fontSize: 14),
            tabs: const [
              Tab(text: 'Shrimp'),
              Tab(text: 'Fish'),
            ],
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _ListingBody(controller: controller),
            _ListingBody(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _ListingBody extends StatefulWidget {
  final SeedWantedController controller;
  const _ListingBody({required this.controller});

  @override
  State<_ListingBody> createState() => _ListingBodyState();
}

class _ListingBodyState extends State<_ListingBody> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (widget.controller.isLoading.value) {
        return Scrollbar(
          thumbVisibility: true,
          controller: _scrollController,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(12, 12, 22, 12),
            itemCount: 4,
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CustomShimmer(
                width: double.infinity,
                height: 140,
              ),
            ),
          ),
        );
      }

      if (widget.controller.listings.isEmpty) {
        return Center(
          child: Text(
            'No listings available.',
            style: GoogleFonts.roboto(fontSize: 15, color: Colors.grey),
          ),
        );
      }

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => widget.controller.fetchListings(),
        child: Scrollbar(
          thumbVisibility: true,
          controller: _scrollController,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(12, 12, 22, 12),
            itemCount: widget.controller.listings.length,
            itemBuilder: (context, index) {
              return _ListingCard(item: widget.controller.listings[index]);
            },
          ),
        ),
      );
    });
  }
}

class _ListingCard extends StatelessWidget {
  final SeedWantedItem item;
  const _ListingCard({required this.item});

  Future<void> _call(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _whatsapp(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/91$cleaned');
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Title centered ────────────────────────────
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 14),

            // ── Row 1: Count/KG | Price ───────────────────
            Row(
              children: [
                Expanded(
                  child: _FieldCell(
                    label: item.countOrKg == 'count' ? 'Count' : 'KG',
                    value: item.countOrKgValue,
                    icon: Icons.straighten,
                    iconColor: Colors.blue.shade600,
                    highlight: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FieldCell(
                    label: 'Price',
                    value: item.price,
                    icon: Icons.currency_rupee,
                    iconColor: Colors.teal.shade500,
                    highlight: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Row 2: Minimum | Area ─────────────────────
            Row(
              children: [
                Expanded(
                  child: _FieldCell(
                    label: 'Minimum',
                    value: item.minimum,
                    icon: Icons.scale,
                    iconColor: Colors.orange.shade600,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FieldCell(
                    label: 'Area',
                    value: item.area,
                    icon: Icons.location_on,
                    iconColor: Colors.red.shade400,
                  ),
                ),
              ],
            ),

            // ── Payment centered ──────────────────────────
            if (item.payment != null && item.payment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Payment : ${item.payment}',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],

            // ── Buttons ───────────────────────────────────
            if (item.phone != null && item.phone!.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _call(item.phone!),
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text('Call Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _whatsapp(item.phone!),
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('WhatsApp'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF25D366),
                        side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FieldCell extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final Color iconColor;
  final bool highlight;

  const _FieldCell({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: highlight ? Colors.black87 : Colors.grey[500],
                    fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value!,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
