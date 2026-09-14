import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/media_url.dart';
import 'app_network_image.dart';

/// Circular profile avatar that loads via [AppNetworkImage] (CORS-safe on web)
/// and falls back to initials when the URL is missing or fails.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.displayName,
    this.imageUrl,
    this.radius = 36,
    super.key,
  });

  final String displayName;
  final String? imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final resolved = MediaUrl.resolve(imageUrl);
    final size = radius * 2;
    final initials = _initials(displayName);

    Widget fallback() => ColoredBox(
      color: AppColors.selectedFill(context),
      child: Center(
        child: Text(
          initials,
          style: AppTypography.title.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: radius * 0.7,
            color: AppColors.onSelected(context),
          ),
        ),
      ),
    );

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: resolved == null
            ? fallback()
            : AppNetworkImage(
                url: resolved,
                width: size,
                height: size,
                fit: BoxFit.cover,
                memCacheWidth: (size * 3).round().clamp(120, 512),
                error: fallback(),
              ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
