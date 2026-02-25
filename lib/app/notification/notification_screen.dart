import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: orderedKeys.length,
            itemBuilder: (context, sectionIndex) {
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
    if (notification.type == 'booking_status') {
      final bookingId = notification.data?['booking_id'];
      if (bookingId != null) {
        Get.to(() => BookingDetailScreen(bookingId: bookingId.toString()));
      }
    } else {
      // admin_broadcast or other
      Get.to(() => NotificationDetailScreen(
            title: notification.title,
            body: notification.body,
            image: notification.image,
          ));
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
