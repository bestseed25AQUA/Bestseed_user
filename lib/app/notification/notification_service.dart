import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:seedsuser/app/booking/view/booking_detail_screen.dart';
import 'package:seedsuser/app/common/local_storage.dart';
import 'package:seedsuser/app/notification/notification_details_screen.dart';
import 'package:seedsuser/app/utils/network_config.dart';

@pragma('vm-entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message received: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _baseUrl = NetworkConfig.baseURL;

  /// Stores notification data when app is opened from terminated state.
  /// Splash screen will consume this after its own navigation completes.
  static Map<String, dynamic>? pendingNotificationData;

  Future<void> initialize() async {
    // 1. Register Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Request Permissions
    await _requestPermissions();

    // 3. Initialize Local Notifications (for foreground display)
    await _initLocalNotifications();

    // 4. Listen for token Refresh
    _fcm.onTokenRefresh.listen((newToken) {
      _sendTokenToServer(newToken);
    });

    // 5. Set up message handlers
    _setupMessageHandlers();
  }

  /// Call this after user login to register FCM token with auth
  Future<void> registerToken() async {
    String? token;
    if (Platform.isIOS) {
      String? apnsToken = await _fcm.getAPNSToken();
      if (apnsToken != null) {
        token = await _fcm.getToken();
      }
    } else {
      token = await _fcm.getToken();
    }

    if (token != null) {
      print('FCM Token: $token');
      await _sendTokenToServer(token);
    }
  }

  // -- Permissions --
  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: true,
      carPlay: false,
      criticalAlert: false,
    );
    print('Permission status: ${settings.authorizationStatus}');
  }

  // -- Local Notifications --
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create high importance Android notification channel
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  // -- Token Management --
  Future<void> _sendTokenToServer(String token) async {
    try {
      final authToken = await AuthLocalStorage.getToken();
      if (authToken == null) {
        print('No auth token, skipping FCM token registration');
        return;
      }

      await http.post(
        Uri.parse('$_baseUrl/farmer/register-fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'fcm_token': token,
          'device_type': Platform.isAndroid ? 'android' : 'ios',
        }),
      );
      print('FCM token sent to server successfully');
    } catch (e) {
      print('Error sending FCM token to server: $e');
    }
  }

  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received: ${message.data}');
      _showLocalNotification(message);
    });

    // When app is opened from a notification (background -> foreground)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened from background: ${message.data}');
      _handleNotificationTap(message.data);
    });

    // Check if app was opened from a terminated state via notification.
    // Store the data so splash screen can handle it after its own navigation.
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App opened from terminated state via notification: ${message.data}');
        pendingNotificationData = Map<String, dynamic>.from(message.data);
      }
    });
  }

  // -- Show Local Notification --
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    if (notification == null) return;

    // Handle Image Notifications
    // Check data payload first, then fallback to notification payload image
    String? imageUrl = message.data['image']?.toString();
    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = notification.android?.imageUrl ?? notification.apple?.imageUrl;
    }

    BigPictureStyleInformation? bigPictureStyle;
    List<DarwinNotificationAttachment>? iosAttachments;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        print('Loading notification image from: $imageUrl');
        final http.Response response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          // Android: BigPictureStyleInformation
          bigPictureStyle = BigPictureStyleInformation(
            ByteArrayAndroidBitmap(response.bodyBytes),
            contentTitle: notification.title,
            summaryText: notification.body,
          );

          // iOS: Save image to temp file for attachment
          if (Platform.isIOS) {
            try {
              final tempDir = await getTemporaryDirectory();
              final filePath = '${tempDir.path}/notif_${DateTime.now().millisecondsSinceEpoch}.jpg';
              final file = File(filePath);
              await file.writeAsBytes(response.bodyBytes);
              iosAttachments = [DarwinNotificationAttachment(filePath)];
            } catch (e) {
              print('Error creating iOS notification attachment: $e');
            }
          }
        } else {
          print('Failed to load notification image: HTTP ${response.statusCode}');
        }
      } catch (e) {
        print('Error loading notification image: $e');
      }
    }

    // Show module name as subText in notification
    final String? module = message.data['module']?.toString();
    final String? subText = (module != null && module.isNotEmpty) ? module : null;

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      subText: subText,
      styleInformation: bigPictureStyle,
    );

    DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      attachments: iosAttachments,
    );

    NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use a unique notification ID to prevent Android from replacing notifications.
    // Priority: message data ID > booking ID > message ID > timestamp-based fallback.
    // notification.hashCode was causing collisions — two notifications with similar
    // content got the same hash, so tapping the 2nd one opened the 1st one's payload.
    int notifId;
    final dataId = message.data['id'] ?? message.data['booking_id'] ?? message.data['notification_id'];
    if (dataId != null) {
      notifId = int.tryParse(dataId.toString()) ?? DateTime.now().millisecondsSinceEpoch % 100000;
    } else if (message.messageId != null) {
      notifId = message.messageId.hashCode;
    } else {
      notifId = DateTime.now().millisecondsSinceEpoch % 100000;
    }

    await _localNotifications.show(
      id: notifId,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
      payload: jsonEncode(message.data),
    );
  }

  // -- Notification Tap Handlers --
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _handleNotificationTap(Map<String, dynamic>.from(data));
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final String? type = data['type'];

    switch (type) {
      case 'admin_broadcast':
        // Navigate to Notification Detail Screen
        final title = data['title'] ?? '';
        final body = data['body'] ?? '';
        final image = data['image'] ?? '';
        final module = data['module'] ?? '';
        Get.to(() => NotificationDetailScreen(
              title: title,
              body: body,
              image: image,
              module: module,
            ));
        break;

      case 'booking_status':
        final bookingId = data['booking_id'];
        if (bookingId != null) {
          Get.to(() => BookingDetailScreen(bookingId: bookingId));
        }
        break;

      case 'driver_approaching':
        final bookingId = data['booking_id'];
        if (bookingId != null) {
          Get.to(() => BookingDetailScreen(bookingId: bookingId));
        }
        break;

      default:
        print('Unknown notification type: $type');
    }
  }

  /// Call this after splash screen navigation to handle any pending notification.
  static void handlePendingNotification() {
    if (pendingNotificationData != null) {
      final data = pendingNotificationData!;
      pendingNotificationData = null;
      NotificationService()._handleNotificationTap(data);
    }
  }

  // -- Topic Subscription --
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  Future<void> unSubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }
}
