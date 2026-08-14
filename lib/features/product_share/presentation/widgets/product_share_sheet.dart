import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/error/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/product_share_providers.dart';
import '../../domain/models/product_share.dart';

Future<void> showProductShareSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String productId,
  required String productType,
  required String productTitle,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.warmWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.s16,
          right: AppSpacing.s16,
          top: AppSpacing.s16,
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + AppSpacing.s24,
        ),
        child: _ProductShareSheet(
          productId: productId,
          productType: productType,
          productTitle: productTitle,
        ),
      );
    },
  );
}

class _ProductShareSheet extends ConsumerStatefulWidget {
  const _ProductShareSheet({
    required this.productId,
    required this.productType,
    required this.productTitle,
  });

  final String productId;
  final String productType;
  final String productTitle;

  @override
  ConsumerState<_ProductShareSheet> createState() => _ProductShareSheetState();
}

class _ProductShareSheetState extends ConsumerState<_ProductShareSheet> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  var _busy = false;
  var _includePrice = true;
  var _includeImages = true;
  var _includeVideos = true;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _notify(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<ProductShareLink?> _create(ProductShareChannel channel) async {
    final result =
        await ref.read(productShareControllerProvider.notifier).create(
              productType: widget.productType,
              productId: widget.productId,
              channel: channel,
              includePrice: _includePrice,
              includeImages: _includeImages,
              includeVideos: _includeVideos,
            );
    switch (result) {
      case Success(value: final link):
        return link;
      case ResultFailure(failure: final failure):
        _notify(failure.message);
        return null;
    }
  }

  Future<void> _shareWhatsApp() async {
    if (_busy) return;
    setState(() => _busy = true);
    final link = await _create(ProductShareChannel.whatsapp);
    if (!mounted) return;
    setState(() => _busy = false);
    if (link == null) return;

    final text = Uri.encodeComponent(
      '${widget.productTitle}\n${link.shareUrl}',
    );
    final uri = Uri.parse('https://wa.me/?text=$text');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      await Clipboard.setData(ClipboardData(text: link.shareUrl));
      if (!mounted) return;
      _notify('WhatsApp unavailable — share link copied');
    } else if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _shareEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _notify('Enter a valid email address');
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    final link = await _create(ProductShareChannel.email);
    if (link == null) {
      if (mounted) setState(() => _busy = false);
      return;
    }
    final result =
        await ref.read(productShareControllerProvider.notifier).sendEmail(
              shareId: link.id,
              email: email,
              name: _nameController.text.trim().isEmpty
                  ? null
                  : _nameController.text.trim(),
            );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success():
        _notify('Share email sent to $email');
        Navigator.of(context).maybePop();
      case ResultFailure(failure: final failure):
        _notify(failure.message);
    }
  }

  Future<void> _copyLink() async {
    if (_busy) return;
    setState(() => _busy = true);
    final link = await _create(ProductShareChannel.whatsapp);
    if (!mounted) return;
    setState(() => _busy = false);
    if (link == null) return;
    await Clipboard.setData(ClipboardData(text: link.shareUrl));
    if (!mounted) return;
    _notify('Share link copied');
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Share product',
            style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            widget.productTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            'Include in share',
            style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Recipients only see what you select — like Nivoda / RapNet shares.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: _includePrice,
            onChanged: _busy
                ? null
                : (v) => setState(() => _includePrice = v ?? false),
            title: Text(
              'Price',
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.bronze,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: _includeImages,
            onChanged: _busy
                ? null
                : (v) => setState(() => _includeImages = v ?? false),
            title: Text(
              'Images',
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.bronze,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: _includeVideos,
            onChanged: _busy
                ? null
                : (v) => setState(() => _includeVideos = v ?? false),
            title: Text(
              'Videos / 360°',
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.bronze,
          ),
          const Divider(height: 24),
          if (_busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            Text(
              'Share via',
              style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.chat, color: AppColors.bronze),
              title: const Text('WhatsApp'),
              subtitle: const Text('Opens WhatsApp with an in-app share link'),
              onTap: _shareWhatsApp,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.link, color: AppColors.bronze),
              title: const Text('Copy link'),
              subtitle: const Text('Link opens this product inside GemWorld'),
              onTap: _copyLink,
            ),
            const Divider(height: 24),
            Text(
              'Email',
              style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.s8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Recipient email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Recipient name (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            FilledButton.icon(
              onPressed: _shareEmail,
              icon: const Icon(Icons.email_outlined),
              label: const Text('Send email'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.charcoal,
                foregroundColor: AppColors.warmWhite,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
