import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:seedsuser/app/notification/controller/notification_controller.dart';
import 'package:seedsuser/app/notification/model/push_notification_model.dart';
import 'package:seedsuser/app/notification/notification_details_screen.dart';
import 'package:seedsuser/app/booking/view/booking_detail_screen.dart';
import 'package:seedsuser/app/utils/network_config.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NotificationController());

    return Scaffold(
      appBar: CustomAppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.roboto(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final grouped = controller.groupedNotifications;
        // Maintain order: Today -> Yesterday -> Earlier
        final orderedKeys = ['Today', 'Yesterday', 'Earlier']
            .where((k) => grouped.containsKey(k))
            .toList();

        return RefreshIndicator(
          onRefresh: controller.fetchNotifications,
          child: ListView.builder(
            controller: controller.scrollController,
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: orderedKeys.length + (controller.hasMore ? 1 : 0),
            itemBuilder: (context, sectionIndex) {
              if (sectionIndex >= orderedKeys.length) {
                return const _ShimmerDotsLoader();
              }

              final label = orderedKeys[sectionIndex];
              final items = grouped[label]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      label,
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...items.map((notification) => _NotificationCard(
                        notification: notification,
                        onTap: () {
                          controller.markAsRead(notification.id);
                          _handleNotificationTap(notification);
                        },
                      )),
                ],
              );
            },
          ),
        );
      }),
    );
  }

  void _handleNotificationTap(PushNotificationModel notification) {
    debugPrint('🔔 [NOTIF TAP] id=${notification.id} type="${notification.type}" '
        'module="${notification.module}" data=${notification.data}');

    try {
      // Booking notifications WITH a usable booking id → booking details.
      if (notification.type == 'booking_status') {
        final bookingId =
            notification.data?['booking_id'] ?? notification.data?['id'];
        if (bookingId != null && bookingId.toString().isNotEmpty) {
          debugPrint('🔔 [NOTIF TAP] → BookingDetailScreen(bookingId=$bookingId)');
          Get.to(
            () => BookingDetailScreen(bookingId: bookingId.toString()),
            preventDuplicates: false,
          );
          return;
        }
        debugPrint('🔔 [NOTIF TAP] booking_status but no usable booking id '
            '→ falling back to NotificationDetailScreen');
      }

      // Everything else — admin broadcasts AND any notification without a usable
      // booking id — opens the detail screen, so a tap ALWAYS does something
      // instead of silently dead-ending (only showing the card ripple).
      final hatcheryId = notification.data?['hatchery_id']?.toString();
      final hatcheryName = notification.data?['hatchery_name']?.toString();
      debugPrint('🔔 [NOTIF TAP] → NotificationDetailScreen('
          'module="${notification.module}", hatcheryId=$hatcheryId, '
          'hatcheryName=$hatcheryName)');
      // preventDuplicates: false — NotificationDetailScreen is closed with the
      // app-bar/system back (Navigator.pop), which can leave GetX's tracked
      // "current route" still pointing at /NotificationDetailScreen. Without
      // this, tapping a second notification of the same screen is blocked by
      // the duplicate guard and nothing happens (only the card ripple shows).
      Get.to(
        () => NotificationDetailScreen(
          title: notification.title,
          body: notification.body,
          image: notification.image,
          module: notification.module,
          hatcheryId: hatcheryId,
          hatcheryName: hatcheryName,
        ),
        preventDuplicates: false,
      );
      debugPrint('🔔 [NOTIF TAP] navigation dispatched OK');
    } catch (e, s) {
      debugPrint('❌ [NOTIF TAP] navigation FAILED: $e');
      debugPrint('❌ [NOTIF TAP] stack: $s');
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final PushNotificationModel notification;
  final VoidCallback? onTap;

  const _NotificationCard({
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Build image URL
    String? imageUrl;
    if (notification.image != null && notification.image!.isNotEmpty) {
      if (notification.image!.startsWith('http')) {
        imageUrl = notification.image;
      } else {
        imageUrl = '${NetworkConfig.imageURL}/${notification.image}';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Card(
          elevation: notification.isRead ? 1 : 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    height: 150,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (notification.module != null && notification.module!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            notification.module!,
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: GoogleFonts.roboto(color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerDotsLoader extends StatelessWidget {
  const _ShimmerDotsLoader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            period: Duration(milliseconds: 800 + (index * 200)),
            child: Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ),
    );
  }
}
