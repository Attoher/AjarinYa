import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ajarin_ya/firebase_options.dart';
import 'package:ajarin_ya/views/barter_request_screen.dart';

/// Handler pesan FCM saat aplikasi berada di background atau sudah ditutup
/// (terminated). Wajib berupa top-level function (bukan method di dalam class)
/// agar bisa dijalankan oleh Flutter di isolate terpisah.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Isolate background terpisah dari isolate utama, sehingga Firebase
  // perlu diinisialisasi ulang sebelum dipakai.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  developer.log('Pesan FCM diterima saat background: ${message.messageId}', name: 'FCM');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Key navigator global supaya notifikasi yang di-tap bisa mengarahkan
  /// pengguna ke layar yang relevan tanpa butuh BuildContext lokal.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const String _channelId = 'ajarinya_channel';
  static const String _channelName = 'Notifikasi AjarinYa';
  static const String _channelDescription =
      'Notifikasi pesan chat dan tawaran trade skill di AjarinYa';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Inisialisasi Firebase Cloud Messaging beserta tampilan notifikasi
  /// sistem (di luar aplikasi) untuk pesan chat dan tawaran trade skill.
  Future<void> initFirebaseMessaging() async {
    try {
      await _initLocalNotifications();

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      developer.log('Status izin notifikasi: ${settings.authorizationStatus}', name: 'FCM');

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Saat aplikasi sedang dibuka (foreground), FCM tidak otomatis
      // menampilkan notifikasi sistem, sehingga kita tampilkan secara manual.
      FirebaseMessaging.onMessage.listen(_showLocalNotification);

      // Saat notifikasi sistem (dikirim FCM) di-tap ketika aplikasi
      // berjalan di background.
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _handleNotificationTap(message.data);
      });

      // Saat aplikasi dibuka dari kondisi tertutup (terminated) lewat tap
      // notifikasi.
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleNotificationTap(initialMessage.data);
        });
      }
    } catch (e) {
      developer.log('FCM init failed: $e', name: 'FCM');
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          _handleNotificationTap(data);
        } catch (e) {
          developer.log('Gagal membaca payload notifikasi: $e', name: 'FCM');
        }
      },
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Menampilkan pesan FCM yang masuk ketika aplikasi sedang foreground
  /// sebagai notifikasi sistem (muncul di status bar / tray notifikasi),
  /// sehingga perilakunya konsisten dengan saat aplikasi di background.
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final type = message.data['type'] as String?;
    final title = notification?.title ?? _defaultTitleForType(type);
    final body = notification?.body ?? (message.data['body'] as String? ?? '');

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  String _defaultTitleForType(String? type) {
    switch (type) {
      case 'chat':
        return 'Pesan Baru';
      case 'barter_offer':
        return 'Tawaran Skill Baru';
      case 'barter_matched':
        return 'Tawaran Diterima';
      default:
        return 'AjarinYa';
    }
  }

  /// Mengarahkan pengguna ke layar yang relevan berdasarkan tipe notifikasi
  /// yang di-tap (pesan chat atau tawaran trade skill).
  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (type == 'chat' || type == 'barter_offer' || type == 'barter_matched') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const BarterRequestScreen()),
      );
    }
  }

  /// Mengambil token unik perangkat untuk dikirimi push notification.
  Future<String?> getDeviceToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      developer.log('Gagal mengambil FCM token: $e', name: 'FCM');
      return null;
    }
  }

  /// Stream token baru setiap kali FCM merotasi token perangkat.
  Stream<String> get onTokenRefresh => FirebaseMessaging.instance.onTokenRefresh;

  /// Menampilkan simulasi push notifikasi melayang (in-app banner)
  /// dengan animasi slide-down dan fade-in.
  void showNotification({
    required BuildContext context,
    required String title,
    required String message,
    IconData icon = Icons.notifications_active_rounded,
    Color accentColor = const Color(0xFF0D47A1),
  }) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return _NotificationBanner(
          title: title,
          message: message,
          icon: icon,
          accentColor: accentColor,
          onDismiss: () {
            overlayEntry.remove();
          },
        );
      },
    );

    overlayState.insert(overlayEntry);
  }
}

class _NotificationBanner extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onDismiss;

  const _NotificationBanner({
    required this.title,
    required this.message,
    required this.icon,
    required this.accentColor,
    required this.onDismiss,
  });

  @override
  State<_NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<_NotificationBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _yTranslation;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _yTranslation = Tween<double>(begin: -100, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Positioned(
      top: media.padding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _yTranslation.value),
              child: Opacity(
                opacity: _opacity.value,
                child: GestureDetector(
                  onTap: _dismiss,
                  onVerticalDragUpdate: (details) {
                    if (details.primaryDelta! < -5) {
                      _dismiss();
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: widget.accentColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: widget.accentColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.icon,
                            color: widget.accentColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Color(0xFF1A1A2E),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.message,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.close,
                          color: Colors.grey.shade400,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
