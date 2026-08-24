import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
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
    showDragHandle: true,
    backgroundColor: AppColors.card(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.s16,
          right: AppSpacing.s16,
          top: AppSpacing.s8,
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
  var _showEmailForm = false;

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

  Future<void> _shareNative() async {
    if (_busy) return;
    setState(() => _busy = true);
    final link = await _create(ProductShareChannel.whatsapp);
    if (!mounted) return;
    setState(() => _busy = false);
    if (link == null) return;

    final text = '${widget.productTitle}\n${link.shareUrl}';
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: widget.productTitle,
        sharePositionOrigin: origin,
      ),
    );
    if (mounted) Navigator.of(context).maybePop();
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
    final secondary = AppColors.textSecondary(context);

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
            style: AppTypography.caption.copyWith(color: secondary),
          ),
          const SizedBox(height: AppSpacing.s16),
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
            const SizedBox(height: AppSpacing.s12),
            SizedBox(
              height: 92,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _ShareChannelButton(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    onTap: _shareNative,
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  _ShareChannelButton(
                    icon: Icons.chat,
                    label: 'WhatsApp',
                    onTap: _shareWhatsApp,
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  _ShareChannelButton(
                    icon: Icons.link,
                    label: 'Copy link',
                    onTap: _copyLink,
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  _ShareChannelButton(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    onTap: () => setState(() => _showEmailForm = true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            _ShareActionTile(
              icon: Icons.share_outlined,
              title: 'Share to apps',
              subtitle: 'Opens your device share sheet (Messages, Mail, etc.)',
              onTap: _shareNative,
            ),
            _ShareActionTile(
              icon: Icons.link,
              title: 'Copy link',
              subtitle: 'Link opens this product inside GemWorld',
              onTap: _copyLink,
            ),
            _ShareActionTile(
              icon: Icons.email_outlined,
              title: 'Send email',
              subtitle: 'Share with price, images, and video options above',
              onTap: () => setState(() => _showEmailForm = true),
            ),
            if (_showEmailForm) ...[
              const Divider(height: 24),
              Text(
                'Email recipient',
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
        ],
      ),
    );
  }
}

class _ShareChannelButton extends StatelessWidget {
  const _ShareChannelButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.r8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Icon(icon, color: AppColors.bronze),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareActionTile extends StatelessWidget {
  const _ShareActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.bronze),
      title: Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: AppTypography.caption.copyWith(color: AppColors.textMuted(context)),
      ),
      onTap: onTap,
    );
  }
}
