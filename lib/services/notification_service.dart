import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Menampilkan simulasi push notifikasi melayang (in-app banner) premium dengan
  /// animasi slide-down dan fade-in. Sangat menawan dan andal saat didemokan.
  void showNotification({
    required BuildContext context,
    required String title,
    required String message,
    IconData icon = Icons.notifications_active_rounded,
    Color accentColor = const Color(0xFF8B5CF6), // Purple accent
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
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0F172A), // Dark Slate
                          Color(0xFF1E293B),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: widget.accentColor.withOpacity(0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.accentColor.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Animated pulsing background for Icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: widget.accentColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.accentColor.withOpacity(0.3),
                              width: 1,
                            ),
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
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.message,
                                style: TextStyle(
                                  color: Colors.grey.shade300,
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
                          Icons.drag_handle_rounded,
                          color: Colors.grey.shade600,
                          size: 20,
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
