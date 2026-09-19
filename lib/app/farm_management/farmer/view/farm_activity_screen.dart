import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:seedsuser/app/common/safe_back.dart';
import 'package:seedsuser/app/farm_management/farmer/controller/farm_activity_controller.dart';
import 'package:seedsuser/app/farm_management/farmer/model/farm_activity_model.dart';

/// Who changed what on this farm, over the last fifteen days.
///
/// A farm is worked by several people at once — the owner, partners, managers,
/// and an admin on the phone to any of them. When a figure looks wrong there
/// was no way to ask who put it there, so every disagreement came down to one
/// person's word against another's.
///
/// Readable by the owner and partners only. A manager's own changes appear in
/// here; being in the log and being able to read it are different things.
class FarmActivityScreen extends StatefulWidget {
  final String farmId;
  final String farmName;

  /// Set when opened from a tank, to narrow the whole screen to it.
  final int? tankId;
  final String? tankName;

  const FarmActivityScreen({
    super.key,
    required this.farmId,
    required this.farmName,
    this.tankId,
    this.tankName,
  });

  @override
  State<FarmActivityScreen> createState() => _FarmActivityScreenState();
}

class _FarmActivityScreenState extends State<FarmActivityScreen> {
  // Tagged with the farm id so two farms opened in turn do not share one
  // controller and show each other's history for a frame.
  late final FarmActivityController controller = Get.put(
    FarmActivityController(),
    tag: 'activity-${widget.farmId}',
  );

  int get _farmIdNum => int.tryParse(widget.farmId) ?? 0;

  @override
  void initState() {
    super.initState();
    controller.tankId = widget.tankId;
    controller.load(_farmIdNum);
  }

  @override
  void dispose() {
    Get.delete<FarmActivityController>(tag: 'activity-${widget.farmId}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: CustomAppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => safeBack(),
        ),
        // A single Text: CustomAppBar takes no subtitle, so what this history
        // is OF goes in the strip at the top of the body instead.
        title: Text(
          'History',
          style: GoogleFonts.roboto(color: Colors.white),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final denied = controller.deniedMessage.value;
        if (denied != null) {
          return _notice(Icons.lock_outline_rounded, denied);
        }

        if (controller.hasError.value) {
          return _notice(
            Icons.cloud_off_rounded,
            'Could not load the history. Pull down to try again.',
            onRetry: () => controller.load(_farmIdNum),
          );
        }

        final feed = controller.feed.value;

        return RefreshIndicator(
          onRefresh: () => controller.load(_farmIdNum, silent: true),
          child: Column(
            children: [
              _scope(feed.windowDays),
              _filters(feed),
              Expanded(
                child: feed.entries.isEmpty
                    ? _empty(feed.windowDays)
                    : _list(feed),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// What this history is of, and how far back it goes.
  ///
  /// Named rather than assumed: a farmer arriving here from a tank should see
  /// that they are looking at that tank, and the window has to be stated or an
  /// empty screen reads as "nothing ever happened".
  Widget _scope(int windowDays) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Text(
        '${widget.tankName ?? widget.farmName} · last $windowDays days',
        style: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _filters(FarmActivityFeed feed) {
    if (feed.categories.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: SizedBox(
        height: 32,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _chip('All', controller.category.value == null, () {
              controller.filterBy(_farmIdNum, null);
            }),
            for (final category in feed.categories)
              _chip(
                category.label,
                controller.category.value == category.key,
                () => controller.filterBy(_farmIdNum, category.key),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Grouped by day, so a farm changed twenty times in a week reads as five
  /// days rather than one undifferentiated column of rows.
  Widget _list(FarmActivityFeed feed) {
    final days = feed.byDay;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: index == 0 ? 0 : 18, bottom: 8),
              child: Text(
                day.key,
                style: GoogleFonts.roboto(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            ...day.value.map(_entryCard),
          ],
        );
      },
    );
  }

  Widget _entryCard(FarmActivity entry) {
    final colour = _actionColour(entry.action);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colour.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_categoryIcon(entry.category), size: 17, color: colour),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.description,
                  style: GoogleFonts.roboto(
                    fontSize: 13.5,
                    height: 1.35,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      entry.actorLabel,
                      style: GoogleFonts.roboto(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if ((entry.actorRole ?? '').isNotEmpty)
                      _tag(entry.actorRole!, Colors.blueGrey),
                    if ((entry.tankName ?? '').isNotEmpty)
                      _tag(entry.tankName!, Colors.teal),
                    Text(
                      entry.happenedAt ?? '',
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String label, Color colour) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.roboto(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: colour,
          height: 1.5,
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'feed':
        return Icons.restaurant_rounded;
      case 'tank':
        return Icons.water_rounded;
      case 'store':
        return Icons.inventory_2_rounded;
      case 'access':
        return Icons.people_alt_rounded;
      default:
        return Icons.agriculture_rounded;
    }
  }

  Color _actionColour(String action) {
    switch (action) {
      case 'deleted':
      case 'revoked':
        return Colors.red.shade600;
      case 'created':
      case 'granted':
        return Colors.green.shade700;
      case 'harvested':
        return Colors.brown.shade500;
      case 'activated':
        return Colors.blue.shade600;
      default:
        return AppColors.primary;
    }
  }

  /// Names the window, so "nothing here" cannot be read as "nothing ever".
  Widget _empty(int windowDays) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
      children: [
        Icon(Icons.history_rounded, size: 54, color: Colors.grey.shade300),
        const SizedBox(height: 14),
        Text(
          'No changes in the last $windowDays days',
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Anything recorded on this farm — feed, tanks, the store, who has '
          'access — will show up here with who did it and when.',
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(
            fontSize: 12.5,
            height: 1.45,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _notice(IconData icon, String message, {VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 13.5,
                height: 1.45,
                color: Colors.grey.shade700,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}
