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
            'Seed Wanted',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          bottom: TabBar(
            onTap: (index) {
              final species = index == 0 ? 'vannamei' : 'tiger';
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
              Tab(text: 'Vannamei'),
              Tab(text: 'Tiger'),
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

class _ListingBody extends StatelessWidget {
  final SeedWantedController controller;
  const _ListingBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: 4,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CustomShimmer(
              width: double.infinity,
              height: 140,
            ),
          ),
        );
      }

      if (controller.listings.isEmpty) {
        return Center(
          child: Text(
            'No listings available.',
            style: GoogleFonts.roboto(fontSize: 15, color: Colors.grey),
          ),
        );
      }

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => controller.fetchListings(),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          itemCount: controller.listings.length,
          itemBuilder: (context, index) {
            return _ListingCard(item: controller.listings[index]);
          },
        ),
      );
    });
  }
}

class _ListingCard extends StatelessWidget {
  final SeedWantedItem item;
  const _ListingCard({required this.item});

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  Future<void> _whatsapp(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/91$cleaned');
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.species == 'vannamei' ? 'Vannamei' : 'Tiger',
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.title,
                    style: GoogleFonts.roboto(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Info rows
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                if (item.countOrKgValue != null && item.countOrKgValue!.isNotEmpty)
                  _InfoChip(
                    label: item.countOrKg == 'count' ? 'Count' : 'KG',
                    value: item.countOrKgValue!,
                  ),
                if (item.minimum != null && item.minimum!.isNotEmpty)
                  _InfoChip(label: 'Minimum', value: item.minimum!),
                if (item.area != null && item.area!.isNotEmpty)
                  _InfoChip(label: 'Area', value: item.area!),
                if (item.payment != null && item.payment!.isNotEmpty)
                  _InfoChip(label: 'Payment', value: item.payment!),
                if (item.price != null && item.price!.isNotEmpty)
                  _InfoChip(label: 'Price', value: item.price!),
              ],
            ),

            if (item.phone != null && item.phone!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _call(item.phone!),
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text('Call'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green.shade700,
                        side: BorderSide(color: Colors.green.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _whatsapp(item.phone!),
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('Whatsapp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
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

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.roboto(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
