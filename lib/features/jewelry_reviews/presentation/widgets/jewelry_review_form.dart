import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/error/result.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../jewelry_checkout/application/jewelry_orders_provider.dart';
import '../../data/jewelry_review_repository.dart';
import '../../domain/models/jewelry_review.dart';
import 'jewelry_review_stars.dart';

/// Opens the review form for an order line: a new review (with
/// [initialRating] already chosen when the buyer tapped a star), or a
/// change to [existing]. Returns the saved review, or null.
Future<JewelryOwnReview?> showJewelryReviewForm(
  BuildContext context, {
  required String orderId,
  required String orderItemId,
  required String pieceTitle,
  JewelryOwnReview? existing,
  int initialRating = 0,
}) => showLuxeSheet<JewelryOwnReview>(
  context,
  title: context.tr(
    existing == null
        ? JewelryReviewL10n.formTitle
        : JewelryReviewL10n.formEditTitle,
  ),
  subtitle: pieceTitle,
  builder: (_) => _ReviewForm(
    orderId: orderId,
    orderItemId: orderItemId,
    existing: existing,
    initialRating: existing?.rating ?? initialRating,
  ),
);

class _ReviewForm extends ConsumerStatefulWidget {
  const _ReviewForm({
    required this.orderId,
    required this.orderItemId,
    required this.existing,
    required this.initialRating,
  });

  final String orderId;
  final String orderItemId;
  final JewelryOwnReview? existing;
  final int initialRating;

  @override
  ConsumerState<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends ConsumerState<_ReviewForm> {
  late int _rating = widget.initialRating.clamp(0, 5);
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _body = TextEditingController(text: widget.existing?.body);
  late final List<String> _kept = [...?widget.existing?.imageUrls];
  final List<JewelryReviewPhoto> _added = [];
  bool _posting = false;
  String? _error;

  int get _photoCount => _kept.length + _added.length;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  /// `image/jpeg`, `image/png` or `image/webp`; null for anything else
  /// (HEIC and the like are refused by the server).
  static String? _mimeOf(XFile file) {
    final declared = file.mimeType?.toLowerCase().trim();
    const allowed = {'image/jpeg', 'image/png', 'image/webp'};
    if (declared != null && allowed.contains(declared)) return declared;
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
    if (!name.contains('.')) return 'image/jpeg';
    return null;
  }

  Future<void> _addPhotos() async {
    final room = JewelryReviewRules.maxPhotos - _photoCount;
    if (room <= 0) {
      setState(() => _error = context.tr(JewelryReviewL10n.photosMax));
      return;
    }
    final source = kIsWeb
        ? ImageSource.gallery
        : await showModalBottomSheet<ImageSource>(
            context: context,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.photo_camera_outlined),
                    title: Text(context.tr(JewelryReviewL10n.takePhoto)),
                    onTap: () => Navigator.of(context).pop(ImageSource.camera),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library_outlined),
                    title: Text(context.tr(JewelryReviewL10n.choosePhoto)),
                    onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                  ),
                ],
              ),
            ),
          );
    if (source == null || !mounted) return;
    // A quality / width cap makes the picker hand back a compressed JPEG
    // (iPhone HEIC included).
    const quality = 85;
    const maxWidth = 2048.0;
    final picker = ImagePicker();
    List<XFile> files;
    try {
      if (source == ImageSource.gallery && room > 1) {
        files = await picker.pickMultiImage(
          imageQuality: quality,
          maxWidth: maxWidth,
          limit: room,
        );
      } else {
        final one = await picker.pickImage(
          source: source,
          imageQuality: quality,
          maxWidth: maxWidth,
        );
        files = [?one];
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = context.tr(JewelryReviewL10n.photosUnavailable),
        );
      }
      return;
    }
    if (files.isEmpty || !mounted) return;
    String? problem;
    final picked = <JewelryReviewPhoto>[];
    for (final f in files.take(room)) {
      final mime = _mimeOf(f);
      if (mime == null) {
        problem = JewelryReviewL10n.photoType;
        continue;
      }
      final bytes = await f.readAsBytes();
      if (bytes.length > JewelryReviewRules.maxPhotoBytes) {
        problem = JewelryReviewL10n.photoTooBig;
        continue;
      }
      if (bytes.isEmpty) continue;
      picked.add(
        JewelryReviewPhoto(
          bytes: bytes,
          name: f.name.trim().isEmpty ? 'review.jpg' : f.name,
          mimeType: mime,
        ),
      );
    }
    if (files.length > room) problem ??= JewelryReviewL10n.photosMax;
    if (!mounted) return;
    setState(() {
      _added.addAll(picked);
      _error = problem == null ? null : context.tr(problem);
    });
  }

  Future<void> _submit() async {
    if (_posting) return;
    if (_rating < 1) {
      setState(() => _error = context.tr(JewelryReviewL10n.chooseStars));
      return;
    }
    setState(() {
      _posting = true;
      _error = null;
    });
    final repo = ref.read(jewelryReviewRepositoryProvider);
    final existing = widget.existing;
    final result = existing == null
        ? await repo.post(
            orderItemId: widget.orderItemId,
            rating: _rating,
            title: _title.text,
            body: _body.text,
            photos: _added,
          )
        : await repo.edit(
            reviewId: existing.id,
            rating: _rating,
            keepPhotos: _kept,
            title: _title.text,
            body: _body.text,
            photos: _added,
          );
    if (!mounted) return;
    switch (result) {
      case Success(value: (:final review, :final message)):
        showLuxeToast(
          context,
          message ??
              context.tr(
                existing == null
                    ? JewelryReviewL10n.posted
                    : JewelryReviewL10n.updated,
              ),
          tone: LuxeTone.success,
        );
        Navigator.of(context).pop(review);
      case ResultFailure(:final failure):
        final message = jewelryReviewError(failure);
        // Reviewed already (another device, or a double send): show the
        // saved review instead of a dead end.
        if (existing == null &&
            message.toLowerCase().contains('already reviewed')) {
          showLuxeToast(context, message, tone: LuxeTone.info);
          ref.invalidate(jewelryOrderProvider(widget.orderId));
          Navigator.of(context).pop();
          return;
        }
        setState(() {
          _posting = false;
          _error = message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr(JewelryReviewL10n.yourRating).toUpperCase(),
          style: LuxeType.eyebrow(p.inkMuted),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            JewelryStarPicker(
              value: _rating,
              onChanged: (v) => setState(() {
                _rating = v;
                _error = null;
              }),
            ),
            const SizedBox(width: 8),
            if (_rating > 0)
              Expanded(
                child: Text(
                  jewelryStarWord(context, _rating),
                  style: LuxeType.label(p.accent, size: 14),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _title,
          maxLength: JewelryReviewRules.maxTitle,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: context.tr(JewelryReviewL10n.headline),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _body,
          maxLength: JewelryReviewRules.maxBody,
          minLines: 3,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: context.tr(JewelryReviewL10n.body),
            hintText: context.tr(JewelryReviewL10n.bodyHint),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr(JewelryReviewL10n.photos, {'count': _photoCount}),
          style: LuxeType.label(p.inkMuted, size: 12.5),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final url in _kept)
              _Thumb(
                image: AppNetworkImage(url: url, memCacheWidth: 216),
                onRemove: _posting
                    ? null
                    : () => setState(() => _kept.remove(url)),
              ),
            for (final photo in _added)
              _Thumb(
                image: Image.memory(
                  photo.bytes,
                  fit: BoxFit.cover,
                  cacheWidth: 216,
                ),
                onRemove: _posting
                    ? null
                    : () => setState(() => _added.remove(photo)),
              ),
            if (_photoCount < JewelryReviewRules.maxPhotos)
              _AddTile(onTap: _posting ? null : _addPhotos),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: LuxeType.label(p.caution, size: 13)),
        ],
        const SizedBox(height: 14),
        LuxeButton(
          label: context.tr(
            widget.existing == null
                ? JewelryReviewL10n.post
                : JewelryReviewL10n.save,
          ),
          variant: LuxeButtonVariant.accent,
          expand: true,
          loading: _posting,
          onPressed: _posting ? null : _submit,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.image, required this.onRemove});

  final Widget image;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 72,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: image),
          Positioned(
            top: 2,
            right: 2,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: Colors.white,
                    semanticLabel: MaterialLocalizations.of(
                      context,
                    ).deleteButtonTooltip,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Semantics(
      button: true,
      label: context.tr(JewelryReviewL10n.addPhoto),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: p.surfaceRaised,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: p.hairline),
          ),
          child: Icon(Icons.add_a_photo_outlined, color: p.accent),
        ),
      ),
    );
  }
}
