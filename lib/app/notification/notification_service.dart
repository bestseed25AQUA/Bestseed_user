import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:seedsuser/app/announcement/announcement_prompt_service.dart';
import 'package:seedsuser/app/announcement/announcement_screen.dart';
import 'package:seedsuser/app/auth/view/login_screen.dart';
import 'package:seedsuser/app/booking/view/booking_detail_screen.dart';
import 'package:seedsuser/app/common/force_logout_notice.dart';
import 'package:seedsuser/app/common/local_storage.dart';
import 'package:seedsuser/app/notification/notification_details_screen.dart';
import 'package:seedsuser/app/rating/rating_prompt_service.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Background-isolate token wipe for force_logout. Mirrors the keys held
/// by AuthLocalStorage; can't import that class here because background
/// handlers run in a separate isolate without GetIt/Get state.
Future<void> _clearUserSessionInBackground() async {
  try {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('user_token');
    await sp.remove('user_mobile');
    // Raise the notice flag so the login screen explains why, when reopened.
    // (Same key as ForceLogoutNotice — this isolate can't use that class.)
    await sp.setBool('force_logout_pending', true);
  } catch (e) {
    print('FCM bg force-logout: failed to clear prefs -> $e');
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message received: ${message.messageId}');

  // Force-logout pushed when the user logs in on another device. Clear
  // the session immediately so reopening the app drops the user on login.
  if (message.data['type'] == 'force_logout') {
    await _clearUserSessionInBackground();
    return; // suppress the notification banner — silent logout
  }

  // Backend now sends Android as data-only (no `notification` block) so the
  // FCM SDK does NOT auto-display anything. This handler owns the display
  // for background/killed on Android — without it, the user gets nothing.
  // iOS never reaches this path for alert pushes (APNs displays natively).
  await _showLocalNotificationFromMessage(message);
}

/// Pulls a printable string out of the FCM payload, preferring the `data`
/// block (new backend contract) and falling back to the legacy `notification`
/// block for messages still in-flight during the rollout.
String? _pickField(dynamic dataValue, String? notificationValue) {
  final s = dataValue?.toString();
  if (s != null && s.isNotEmpty && s != 'null') return s;
  return notificationValue;
}

/// Assemble + display a local notification from an FCM message. Called from
/// both the foreground `onMessage` handler and the background isolate's
/// `_firebaseMessagingBackgroundHandler`, so it must be a top-level function
/// (background isolates can't reach class methods) and it must initialize
/// its own FlutterLocalNotificationsPlugin — the main-isolate instance is
/// unreachable from a background isolate.
@pragma('vm:entry-point')
Future<void> _showLocalNotificationFromMessage(
  RemoteMessage message, {
  bool initializePlugin = true,
}) async {
  final localNotifications = FlutterLocalNotificationsPlugin();

  // ONLY the background isolate may initialize here.
  //
  // initialize() is NOT idempotent with respect to callbacks: it assigns
  // `_onDidReceiveNotificationResponse = onDidReceiveNotificationResponse`
  // unconditionally, and FlutterLocalNotificationsPlugin is a singleton. So
  // calling it again on the MAIN isolate without passing the tap callback
  // silently sets that callback to null — after which tapping any
  // notification does nothing at all (the plugin dispatches via
  // `_onDidReceiveNotificationResponse?.call(...)`).
  //
  // That is exactly what happened on the foreground path: showing a
  // notification wiped the handler registered in NotificationService
  // .initialize(), so booking_status / journey-started taps stopped
  // navigating. The background isolate is a separate isolate with its own
  // plugin state, so initializing there is both required and harmless.
  if (initializePlugin) {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await localNotifications.initialize(
      settings: const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );
  }

  // Ensure the high-importance channel exists on this isolate too.
  const androidChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );
  await localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(androidChannel);

  final title = _pickField(message.data['title'], message.notification?.title);
  final body = _pickField(message.data['body'], message.notification?.body);
  final imageUrl = _pickField(
    message.data['image'],
    message.notification?.android?.imageUrl ??
        message.notification?.apple?.imageUrl,
  );

  // Nothing to display — skip silently. Guards against silent control
  // messages that don't carry a title/body but aren't `force_logout`.
  if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
    return;
  }

  BigPictureStyleInformation? bigPictureStyle;
  List<DarwinNotificationAttachment>? iosAttachments;

  if (imageUrl != null && imageUrl.isNotEmpty) {
    try {
      final http.Response response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        bigPictureStyle = BigPictureStyleInformation(
          ByteArrayAndroidBitmap(response.bodyBytes),
          contentTitle: title,
          summaryText: body,
        );
        if (Platform.isIOS) {
          try {
            final tempDir = await getTemporaryDirectory();
            final filePath =
                '${tempDir.path}/notif_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final file = File(filePath);
            await file.writeAsBytes(response.bodyBytes);
            iosAttachments = [DarwinNotificationAttachment(filePath)];
          } catch (e) {
            print('Error creating iOS notification attachment: $e');
          }
        }
      }
    } catch (e) {
      print('Error loading notification image: $e');
    }
  }

  final String? module = message.data['module']?.toString();
  final String? subText =
      (module != null && module.isNotEmpty) ? module : null;

  final androidDetails = AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    channelDescription: 'This channel is used for important notifications.',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    subText: subText,
    styleInformation: bigPictureStyle,
  );
  final iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    attachments: iosAttachments,
  );
  final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

  // Prefer a stable ID from the payload so subsequent updates for the same
  // booking/notification replace instead of stack. hashCode fallback keeps
  // unique messages distinct.
  int notifId;
  final dataId = message.data['id'] ??
      message.data['booking_id'] ??
      message.data['notification_id'];
  if (dataId != null) {
    notifId = int.tryParse(dataId.toString()) ??
        DateTime.now().millisecondsSinceEpoch % 100000;
  } else if (message.messageId != null) {
    notifId = message.messageId.hashCode;
  } else {
    notifId = DateTime.now().millisecondsSinceEpoch % 100000;
  }

  await localNotifications.show(
    id: notifId,
    title: title,
    body: body,
    notificationDetails: details,
    payload: jsonEncode(message.data),
  );
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
      // APNs token is delivered asynchronously by iOS — can take 1-3 seconds
      // after launch (longer on cold start). Single-shot getAPNSToken() was
      // returning null on first call → no FCM registration → no pushes.
      String? apnsToken;
      for (var attempt = 0; attempt < 10; attempt++) {
        apnsToken = await _fcm.getAPNSToken();
        if (apnsToken != null) break;
        await Future.delayed(const Duration(seconds: 1));
      }
      if (apnsToken == null) {
        print('FCM: APNs token still null after 10s — '
            'check Push Notifications capability + APNs key in Firebase');
        return;
      }
      token = await _fcm.getToken();
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

  /// Force-logout the user right now (used when an FCM `force_logout`
  /// message arrives in the foreground because they logged in elsewhere).
  /// Mirrors the network_utils 401 force-logout path.
  Future<void> _handleForceLogout() async {
    print('FCM: force_logout received — clearing user session');
    await ForceLogoutNotice.raise();
    await AuthLocalStorage.clear();
    Get.offAll(() => LoginWithMobileScreen());
  }

  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received: ${message.data}');
      if (message.data['type'] == 'force_logout') {
        _handleForceLogout();
        return;
      }
      // Booking just delivered while the app is open → show the rating popup
      // in real time (in addition to the local notification banner).
      RatingPromptService.instance
          .onDeliveredPush(Map<String, dynamic>.from(message.data));
      // Admin announcement → pop the dialog straight away.
      AnnouncementPromptService.instance
          .onAnnouncementPush(Map<String, dynamic>.from(message.data));
      _showLocalNotification(message);
    });

    // When app is opened from a notification (background -> foreground)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened from background: ${message.data}');
      _handleNotificationTap(message.data);
    });

    // Cold-start tap handling. There are two possible paths:
    //   1. Legacy — FCM auto-displayed the notification (old backend that
    //      sent a `notification` block). getInitialMessage() returns it.
    //   2. New — Android is data-only; the notification was shown by the
    //      background isolate via flutter_local_notifications. FCM's
    //      getInitialMessage() returns null; the tap payload comes from
    //      the local-notifications plugin's launch details instead.
    // Both paths feed the same `pendingNotificationData` slot so the splash
    // screen's consumer doesn't need to know which mechanism delivered it.
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null && pendingNotificationData == null) {
        print('App opened from terminated state via FCM notification: ${message.data}');
        pendingNotificationData = Map<String, dynamic>.from(message.data);
      }
    });
    _localNotifications.getNotificationAppLaunchDetails().then((details) {
      if (details?.didNotificationLaunchApp ?? false) {
        final payload = details?.notificationResponse?.payload;
        if (payload != null && pendingNotificationData == null) {
          try {
            final data = jsonDecode(payload);
            if (data is Map) {
              print('App opened from terminated state via local notification: $data');
              pendingNotificationData = Map<String, dynamic>.from(data);
            }
          } catch (e) {
            print('Failed to decode local notification launch payload: $e');
          }
        }
      }
    });
  }

  // -- Show Local Notification --
  //
  // Delegates to the top-level `_showLocalNotificationFromMessage` so the
  // foreground path and the background-isolate path share exactly one
  // implementation.  The class instance still owns tap handling via
  // `_onNotificationTapped` — flutter_local_notifications routes taps to
  // whichever plugin instance was initialised in the process that receives
  // them, so a notification shown by the background isolate still fires
  // this class's tap handler once the app is brought to the foreground.
  //
  // `initializePlugin: false` is essential: this runs on the MAIN isolate,
  // which already called initialize() with `_onNotificationTapped` in
  // [initialize]. Re-initializing here would overwrite that callback with
  // null and break every notification tap for the rest of the session.
  Future<void> _showLocalNotification(RemoteMessage message) async {
    await _showLocalNotificationFromMessage(message, initializePlugin: false);
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
              hatcheryId: data['hatchery_id']?.toString(),
              hatcheryName: data['hatchery_name']?.toString(),
            ));
        break;

      case 'announcement':
        // Opening from the tray takes the user to the full list; the dialog
        // itself is driven by AnnouncementPromptService on resume.
        Get.to(() => const AnnouncementsScreen());
        break;

      case 'booking_status':
      case 'driver_approaching':
      case 'driver_assigned':
        _openBookingDetail(data);
        break;

      default:
        // A booking id is enough to know where to go, even if the type string
        // is one this build doesn't recognise — better than dropping the tap.
        if (_bookingIdFrom(data) != null) {
          _openBookingDetail(data);
        } else {
          print('Unknown notification type: $type');
        }
    }
  }

  /// Booking id out of a notification payload, or null if there isn't a usable
  /// one. FCM delivers every data value as a string, but the same handler also
  /// receives payloads decoded from local-notification JSON (where an id can
  /// still be an int), so this normalises both and tolerates the `id` spelling.
  static String? _bookingIdFrom(Map<String, dynamic> data) {
    final raw = data['booking_id'] ?? data['id'];
    final id = raw?.toString().trim();
    return (id == null || id.isEmpty) ? null : id;
  }

  void _openBookingDetail(Map<String, dynamic> data) {
    final bookingId = _bookingIdFrom(data);
    if (bookingId == null) {
      print('Notification tap: no usable booking id in $data');
      return;
    }
    print('Notification tap → BookingDetailScreen(bookingId=$bookingId)');
    // preventDuplicates must be off: tapping a notification for booking B
    // while already viewing booking A is the same route, and GetX would
    // otherwise silently swallow the navigation.
    Get.to(
      () => BookingDetailScreen(bookingId: bookingId),
      preventDuplicates: false,
    );
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
