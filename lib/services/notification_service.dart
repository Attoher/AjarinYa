import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer' as developer;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Inisialisasi Firebase Cloud Messaging
  Future<void> initFirebaseMessaging() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      developer.log('User granted permission: ${settings.authorizationStatus}', name: 'FCM');

      // Listen to foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        developer.log('Got a message whilst in the foreground!', name: 'FCM');
        developer.log('Message data: ${message.data}', name: 'FCM');

        if (message.notification != null) {
          developer.log('Message also contained a notification: ${message.notification}', name: 'FCM');
          // We would show the in-app banner here if context was available globally,
          // but usually this is handled at the app root level.
        }
      });
    } catch (e) {
      developer.log('FCM init failed: $e', name: 'FCM');
    }
  }

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
