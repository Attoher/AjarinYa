import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? url;
  final String fallback;
  final double radius;
  final Color backgroundColor;
  final Color fallbackTextColor;

  const UserAvatar({
    super.key,
    this.url,
    required this.fallback,
    this.radius = 20,
    this.backgroundColor = const Color(0xFFE3F2FD),
    this.fallbackTextColor = const Color(0xFF0D47A1),
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = (url ?? '').isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: hasImage ? NetworkImage(url!) : null,
      child: hasImage
          ? null
          : Text(
              fallback.isNotEmpty ? fallback[0].toUpperCase() : '?',
              style: TextStyle(
                color: fallbackTextColor,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.65,
              ),
            ),
    );
  }
}
