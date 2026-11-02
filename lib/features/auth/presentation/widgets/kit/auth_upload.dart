import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/l10n/app_localizations.dart';
import 'auth_tokens.dart';

/// Picks one gallery image with the quality used across registration.
Future<XFile?> pickAuthImage() =>
    ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);

/// Upload row: thumbnail (or dashed placeholder) · title + hint · action.
class AuthUploadTile extends StatelessWidget {
  const AuthUploadTile({
    super.key,
    required this.title,
    required this.hint,
    required this.file,
    required this.onPick,
    this.required = false,
    this.enabled = true,
    this.error = false,
    this.icon = Icons.add_photo_alternate_outlined,
  });

  final String title;
  final String hint;
  final XFile? file;
  final VoidCallback onPick;
  final bool required;
  final bool enabled;
  final bool error;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    final picked = file;
    final borderColor = error
        ? p.danger
        : picked != null
        ? p.accent.withValues(alpha: 0.5)
        : p.hairline;

    return Semantics(
      button: true,
      label: title,
      value: picked?.name,
      child: Material(
        color: picked != null ? p.surfaceFocus : p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AuthSpace.rField),
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onPick : null,
          splashColor: p.accentSoft,
          child: Padding(
            padding: const EdgeInsets.all(AuthSpace.s12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox.square(
                    dimension: 52,
                    child: AnimatedSwitcher(
                      duration: AuthMotion.base,
                      child: picked == null
                          ? CustomPaint(
                              key: const ValueKey('empty'),
                              painter: _DashedRectPainter(
                                color: error ? p.danger : p.hairlineStrong,
                              ),
                              child: Center(
                                child: Icon(icon, size: 22, color: p.accent),
                              ),
                            )
                          : AuthXFileImage(
                              key: ValueKey(picked.path),
                              file: picked,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: AuthSpace.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AuthType.label(p),
                            ),
                          ),
                          const SizedBox(width: AuthSpace.s8),
                          _Tag(
                            text: context.tr(
                              required ? AuthL10n.required : AuthL10n.optional,
                            ),
                            strong: required,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        picked?.name ?? hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AuthType.caption(p).copyWith(
                          color: picked != null ? p.inkSoft : p.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AuthSpace.s8),
                Text(
                  context.tr(
                    picked == null ? AuthL10n.tapToUpload : AuthL10n.replace,
                  ),
                  style: AuthType.caption(
                    p,
                  ).copyWith(color: p.accent, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.strong});

  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: strong ? p.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(AuthSpace.rPill),
        border: Border.all(color: strong ? Colors.transparent : p.hairline),
      ),
      child: Text(
        text,
        style: AuthType.caption(p).copyWith(
          fontSize: 10.5,
          letterSpacing: 0.4,
          color: strong ? p.accent : p.inkMuted,
        ),
      ),
    );
  }
}

/// Circular avatar picker with a camera badge and live preview.
class AuthAvatarPicker extends StatelessWidget {
  const AuthAvatarPicker({
    super.key,
    required this.file,
    required this.onPick,
    this.enabled = true,
  });

  final XFile? file;
  final VoidCallback onPick;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    final picked = file;
    return Semantics(
      button: true,
      label: context.tr(AuthL10n.profilePhoto),
      value: picked?.name,
      child: GestureDetector(
        onTap: enabled ? onPick : null,
        child: Column(
          children: [
            SizedBox.square(
              dimension: 92,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: picked != null ? p.ctaGradient : null,
                        border: picked == null
                            ? Border.all(color: p.hairlineStrong)
                            : null,
                      ),
                      child: ClipOval(
                        child: AnimatedSwitcher(
                          duration: AuthMotion.base,
                          child: picked == null
                              ? Container(
                                  key: const ValueKey('empty'),
                                  color: p.surface,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.person_outline_rounded,
                                    size: 36,
                                    color: p.inkMuted,
                                  ),
                                )
                              : AuthXFileImage(
                                  key: ValueKey(picked.path),
                                  file: picked,
                                ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: p.ctaGradient,
                        border: Border.all(color: p.bg, width: 2.5),
                      ),
                      child: Icon(
                        picked == null
                            ? Icons.add_rounded
                            : Icons.photo_camera_outlined,
                        size: 16,
                        color: p.onCta,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AuthSpace.s8),
            Text(
              context.tr(picked == null ? AuthL10n.addPhoto : AuthL10n.replace),
              style: AuthType.caption(
                p,
              ).copyWith(color: p.accent, fontWeight: FontWeight.w600),
            ),
            Text(
              '${context.tr(AuthL10n.profilePhoto)} · '
              '${context.tr(AuthL10n.optional)}',
              style: AuthType.caption(p).copyWith(fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cross-platform preview for a picked [XFile] (reads bytes once).
class AuthXFileImage extends StatefulWidget {
  const AuthXFileImage({super.key, required this.file});

  final XFile file;

  @override
  State<AuthXFileImage> createState() => _AuthXFileImageState();
}

class _AuthXFileImageState extends State<AuthXFileImage> {
  late Future<Uint8List> _bytes = widget.file.readAsBytes();

  @override
  void didUpdateWidget(AuthXFileImage old) {
    super.didUpdateWidget(old);
    if (old.file.path != widget.file.path) {
      _bytes = widget.file.readAsBytes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snap) {
        final data = snap.data;
        if (data == null) {
          return ColoredBox(
            color: p.surface,
            child: Icon(Icons.image_outlined, color: p.inkMuted, size: 20),
          );
        }
        return Image.memory(
          data,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          cacheWidth: 240,
          errorBuilder: (_, _, _) => ColoredBox(
            color: p.surface,
            child: Icon(Icons.broken_image_outlined, color: p.inkMuted),
          ),
        );
      },
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  const _DashedRectPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.6),
      const Radius.circular(12),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
        d += 8;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) => old.color != color;
}
