import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../buyer/presentation/maison/maison_kit.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../application/spotlight_seller_providers.dart';
import '../../data/spotlight_seller_repository.dart';
import '../../domain/spotlight_models.dart';
import '../../domain/spotlight_seller_models.dart';
import '../widgets/spotlight_product_picker.dart';
import 'seller_spotlight_screen.dart';

/// Books a spotlight and pays from the wallet: placement, section, days,
/// what the ad shows, then the total. Prices and the wallet are in rupees.
class SellerSpotlightBookScreen extends ConsumerWidget {
  const SellerSpotlightBookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(spotlightOverviewProvider);
    return overview.when(
      loading: () => AtelierPage(
        onRefresh: () async {},
        children: const [AtelierSkeletonList(count: 4, height: 110)],
      ),
      error: (e, _) => AtelierPage(
        onRefresh: () async => ref.invalidate(spotlightOverviewProvider),
        children: [
          AtelierErrorState(
            message: spotlightErrorText(e),
            onRetry: () => ref.invalidate(spotlightOverviewProvider),
          ),
        ],
      ),
      data: (o) => o.canBook
          ? _BookingForm(overview: o)
          : AtelierPage(
              onRefresh: () async => ref.invalidate(spotlightOverviewProvider),
              children: [
                AtelierNotice(
                  text:
                      o.blockedReason ??
                      'Advertising opens once your seller account is verified.',
                  tone: AtelierTone.amber,
                  icon: Icons.lock_outline_rounded,
                ),
              ],
            ),
    );
  }
}

class _BookingForm extends ConsumerStatefulWidget {
  const _BookingForm({required this.overview});

  final SpotlightOverview overview;

  @override
  ConsumerState<_BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends ConsumerState<_BookingForm> {
  final _title = TextEditingController();
  final _subtitle = TextEditingController();

  /// Made once per booking and re-sent on retries so a repeat never charges
  /// twice.
  late final String _bookingKey = _newBookingKey();

  SpotlightRate? _rate;
  SpotlightCategory? _category;
  DateTime? _start;
  int _days = 1;

  List<SpotlightDay>? _availability;
  bool _loadingAvailability = false;
  int _availabilityRequest = 0;

  SpotlightCreative? _image;
  SpotlightCreative? _mobileImage;
  bool _uploadingImage = false;
  bool _uploadingMobile = false;
  SpotlightSellerProduct? _linkProduct;
  List<SpotlightSellerProduct> _products = const [];

  bool _submitted = false;
  bool _booking = false;

  /// Total the server quoted after a rate change (AD_PRICE_CHANGED).
  double? _quotedTotal;
  String? _serverError;
  Set<DateTime> _fullDays = const {};

  SpotlightOverview get _o => widget.overview;

  @override
  void initState() {
    super.initState();
    if (_o.placements.length == 1) _selectRate(_o.placements.first);
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    super.dispose();
  }

  static String _newBookingKey() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final r = Random.secure();
    return List.generate(20, (_) => chars[r.nextInt(chars.length)]).join();
  }

  // ── Derived values ────────────────────────────────────────────────────

  DateTime? get _end =>
      _start?.add(Duration(days: _days - 1));

  int get _units => _rate?.isSponsoredProducts ?? false ? _products.length : 1;

  double get _total {
    final rate = _rate;
    if (rate == null) return 0;
    final n = rate.isSponsoredProducts ? _products.length : 1;
    return rate.pricePerDay * _days * n;
  }

  double get _expected => _quotedTotal ?? _total;

  DateTime get _lastStart =>
      _o.today.add(Duration(days: _rate?.bookAheadDays ?? 0));

  List<SpotlightCategory> get _categories => _o.categories.isEmpty
      ? SpotlightCategory.values
      : _o.categories;

  void _changed() {
    _quotedTotal = null;
    _serverError = null;
  }

  // ── Selection ─────────────────────────────────────────────────────────

  void _selectRate(SpotlightRate rate) {
    setState(() {
      _changed();
      _rate = rate;
      _days = _days.clamp(rate.minDays, max(rate.minDays, rate.maxDays)).toInt();
      if (!rate.hasCategory) _category = null;
      if (rate.hasCategory && _category == null && _categories.length == 1) {
        _category = _categories.first;
      }
      if (_start != null &&
          (_start!.isBefore(_o.today) || _start!.isAfter(_lastStart))) {
        _start = null;
      }
      _products = const [];
      _linkProduct = null;
      _availability = null;
      _fullDays = const {};
    });
    _loadAvailability();
  }

  void _selectCategory(SpotlightCategory c) {
    if (c == _category) return;
    setState(() {
      _changed();
      _category = c;
      _products = const [];
      _linkProduct = null;
    });
    _loadAvailability();
  }

  Future<void> _pickStart() async {
    final rate = _rate;
    if (rate == null) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _start ?? _o.today,
      firstDate: _o.today,
      lastDate: _lastStart,
      helpText: 'First day (India time)',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _changed();
      _start = DateTime(picked.year, picked.month, picked.day);
    });
    _loadAvailability();
  }

  void _setDays(int days) {
    final rate = _rate;
    if (rate == null) return;
    final next = days
        .clamp(rate.minDays, max(rate.minDays, rate.maxDays))
        .toInt();
    if (next == _days) return;
    setState(() {
      _changed();
      _days = next;
    });
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final rate = _rate;
    final start = _start;
    final end = _end;
    if (rate == null || start == null || end == null) return;
    if (rate.hasCategory && _category == null) return;
    final request = ++_availabilityRequest;
    setState(() => _loadingAvailability = true);
    final days = <SpotlightDay>[];
    // Up to 120 days per call.
    var from = start;
    while (!from.isAfter(end)) {
      var to = from.add(const Duration(days: 119));
      if (to.isAfter(end)) to = end;
      final result = await ref
          .read(spotlightSellerRepositoryProvider)
          .availability(
            placement: rate.placement,
            category: _category,
            from: from,
            to: to,
          );
      if (!mounted || request != _availabilityRequest) return;
      if (result case Success(:final value)) days.addAll(value);
      from = to.add(const Duration(days: 1));
    }
    setState(() {
      _availability = days;
      _loadingAvailability = false;
      _fullDays = const {};
    });
  }

  Future<void> _pickProducts() async {
    final rate = _rate;
    final category = _category;
    if (rate == null || category == null) return;
    final picked = await showSpotlightProductPicker(
      context: context,
      categories: [category],
      selected: _products,
      max: max(1, rate.maxProducts),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _changed();
      _products = picked;
    });
  }

  Future<void> _pickLinkProduct() async {
    final categories = _category != null ? [_category!] : _categories;
    final picked = await showSpotlightProductPicker(
      context: context,
      categories: categories,
      selected: [?_linkProduct],
      max: 1,
      title: 'Open a product',
    );
    if (picked == null || !mounted) return;
    setState(() => _linkProduct = picked.isEmpty ? null : picked.first);
  }

  Future<void> _upload({required bool mobile}) async {
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(source: ImageSource.gallery);
    } catch (_) {
      return;
    }
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    final mime = spotlightImageMime(file.name);
    final lower = file.name.toLowerCase();
    final typeOk =
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        mime == 'image/jpeg' && !lower.contains('.');
    if (!typeOk) {
      showAtelierToast(
        context,
        'Use a JPEG, PNG or WebP image.',
        tone: AtelierTone.ruby,
      );
      return;
    }
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      showAtelierToast(
        context,
        'That image is over 5 MB. Choose a smaller one.',
        tone: AtelierTone.ruby,
      );
      return;
    }
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final width = frame.image.width;
      frame.image.dispose();
      if (width < 600 && mounted) {
        showAtelierToast(
          context,
          'The image must be at least 600 px wide (it is $width px).',
          tone: AtelierTone.ruby,
        );
        return;
      }
    } catch (_) {
      // Let the server judge images the device can't decode.
    }
    if (!mounted) return;
    setState(() => mobile ? _uploadingMobile = true : _uploadingImage = true);
    final result = await ref
        .read(spotlightSellerRepositoryProvider)
        .uploadCreative(file);
    if (!mounted) return;
    setState(() {
      mobile ? _uploadingMobile = false : _uploadingImage = false;
      if (result case Success(:final value)) {
        if (mobile) {
          _mobileImage = value;
        } else {
          _image = value;
        }
      }
    });
    if (result case ResultFailure(:final failure)) {
      AppHaptics.error();
      showAtelierToast(context, failure.message, tone: AtelierTone.ruby);
    }
  }

  // ── Validation ────────────────────────────────────────────────────────

  String? get _titleError {
    final rate = _rate;
    if (rate == null) return null;
    final t = _title.text.trim();
    if (rate.isBanner) {
      if (t.length < 2) return 'Add a title of at least 2 characters.';
      if (t.length > 60) return 'Keep the title to 60 characters.';
    }
    if (rate.isFeaturedSeller && t.length > 80) {
      return 'Keep the tagline to 80 characters.';
    }
    return null;
  }

  String? get _subtitleError => _subtitle.text.trim().length > 120
      ? 'Keep the subtitle to 120 characters.'
      : null;

  List<SpotlightDay> get _shortDays {
    final days = _availability;
    if (days == null) return const [];
    final need = max(1, _units);
    return [
      for (final d in days)
        if (d.free < need || _fullDays.contains(d.date)) d,
    ];
  }

  String? get _blocker {
    final rate = _rate;
    if (rate == null) return 'Choose a placement.';
    if (rate.hasCategory && _category == null) return 'Choose a section.';
    if (_start == null) return 'Choose the first day.';
    if (rate.isBanner && _image == null) return 'Upload the banner image.';
    if (_titleError != null) return _titleError;
    if (_subtitleError != null) return _subtitleError;
    if (rate.isSponsoredProducts && _products.isEmpty) {
      return 'Pick at least one product.';
    }
    if (_shortDays.isNotEmpty) return 'Some days are fully booked.';
    return null;
  }

  // ── Booking ───────────────────────────────────────────────────────────

  Future<void> _book() async {
    setState(() {
      _submitted = true;
      _serverError = null;
    });
    if (_blocker != null || _booking) {
      AppHaptics.error();
      return;
    }
    final rate = _rate!;
    final total = _expected;
    final ok = await showAtelierConfirm(
      context: context,
      title: 'Pay ${maisonInr(total)}?',
      message:
          'This is charged from your wallet now. The ad runs after GemWorld '
          'approves it; if it is rejected or not reviewed in time, the '
          'payment comes back.',
      confirmLabel: 'Pay and book',
      icon: Icons.campaign_outlined,
    );
    if (!ok || !mounted) return;

    setState(() => _booking = true);
    final request = SpotlightBookingRequest(
      placement: rate.placement,
      category: rate.hasCategory ? _category : null,
      startDate: _start!,
      endDate: _end!,
      expectedAmount: total,
      bookingKey: _bookingKey,
      title: rate.isBanner || rate.isFeaturedSeller ? _title.text : null,
      subtitle: rate.isBanner ? _subtitle.text : null,
      imageUrl: rate.isBanner ? _image?.url : null,
      mobileImageUrl: rate.isBanner ? _mobileImage?.url : null,
      linkProduct: rate.isBanner ? _linkProduct : null,
      products: rate.isSponsoredProducts ? _products : const [],
    );
    final result = await ref
        .read(spotlightSellerRepositoryProvider)
        .book(request);
    if (!mounted) return;
    setState(() => _booking = false);

    switch (result) {
      case Success(:final value):
        AppHaptics.success();
        ref
          ..invalidate(sellerSpotlightAdsProvider)
          ..invalidate(spotlightOverviewProvider);
        showAtelierToast(
          context,
          'Booked. It’s waiting for GemWorld’s review.',
          tone: AtelierTone.emerald,
        );
        if (value.id.isNotEmpty) {
          context.pushReplacement(
            AppRouteNames.sellerSpotlightDetailPath(value.id),
          );
        } else {
          context.pop();
        }
      case ResultFailure(:final failure):
        AppHaptics.error();
        await _onBookingError(failure);
    }
  }

  Future<void> _onBookingError(SpotlightError e) async {
    switch (e.code) {
      case SpotlightError.priceChanged:
        // The rate moved: show the new total before booking again.
        ref.invalidate(spotlightOverviewProvider);
        setState(() {
          _quotedTotal = e.amount;
          _serverError = e.message;
        });
      case SpotlightError.slotsFull:
        setState(() {
          _serverError = e.message;
          _fullDays = {for (final d in e.fullDays) d.date};
        });
        _loadAvailability();
      case SpotlightError.walletTooLow:
        setState(() => _serverError = e.message);
        final need = (e.amount ?? _expected) - (e.availableBalance ?? 0);
        final topUp = await showAtelierConfirm(
          context: context,
          title: 'Top up your wallet',
          message:
              '${e.message}\n\nAdd ${maisonInr(need > 0 ? need : 0)} to book '
              'this ad.',
          confirmLabel: 'Top up',
          icon: Icons.account_balance_wallet_outlined,
        );
        if (topUp && mounted) context.push(AppRouteNames.sellerWallet);
      case SpotlightError.placementClosed:
        ref.invalidate(spotlightOverviewProvider);
        setState(() => _serverError = e.message);
      default:
        setState(() => _serverError = e.message);
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final rate = _rate;
    final blocker = _blocker;

    return AtelierPage(
      onRefresh: () async => ref.invalidate(spotlightOverviewProvider),
      children: [
        Reveal(
          child: Text(
            'Book a spotlight',
            style: AtelierType.display(p.ink, size: 30),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Wallet balance ${maisonInr(_o.availableBalance)} · '
          'ads run on India time',
          style: AtelierType.caption(p.muted, size: 12.5),
        ),
        const SizedBox(height: AtelierSpace.s24),
        _step('1', 'Placement'),
        const SizedBox(height: AtelierSpace.s10),
        if (_o.placements.isEmpty)
          const AtelierNotice(
            text: 'No placement is open for booking right now.',
            tone: AtelierTone.amber,
          )
        else
          for (final r in _o.placements)
            Padding(
              padding: const EdgeInsets.only(bottom: AtelierSpace.s8),
              child: _RateCard(
                rate: r,
                selected: identical(r, rate),
                onTap: () => _selectRate(r),
              ),
            ),
        if (rate != null) ...[
          if (rate.hasCategory) ...[
            const SizedBox(height: AtelierSpace.s20),
            _step('2', 'Section'),
            const SizedBox(height: AtelierSpace.s10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in _categories)
                  AtelierChoiceChip(
                    label: spotlightCategoryName(c),
                    selected: c == _category,
                    onTap: () => _selectCategory(c),
                  ),
              ],
            ),
            if (_submitted && _category == null)
              const AtelierFieldError(error: 'Choose a section.'),
          ],
          const SizedBox(height: AtelierSpace.s20),
          _step(rate.hasCategory ? '3' : '2', 'Dates'),
          const SizedBox(height: AtelierSpace.s10),
          _datesCard(rate),
          const SizedBox(height: AtelierSpace.s20),
          _step(rate.hasCategory ? '4' : '3', 'What it shows'),
          const SizedBox(height: AtelierSpace.s10),
          _contentCard(rate),
          const SizedBox(height: AtelierSpace.s20),
          _summary(rate),
          if (_serverError != null) ...[
            const SizedBox(height: AtelierSpace.s12),
            AtelierNotice(
              text: _serverError!,
              tone: AtelierTone.ruby,
              icon: Icons.error_outline_rounded,
            ),
          ],
          if (_submitted && blocker != null && _serverError == null) ...[
            const SizedBox(height: AtelierSpace.s12),
            AtelierNotice(text: blocker, tone: AtelierTone.amber, dense: true),
          ],
          const SizedBox(height: AtelierSpace.s16),
          AtelierButton(
            label: _booking
                ? 'Booking…'
                : 'Pay ${maisonInr(_expected)} and book',
            icon: Icons.lock_outline_rounded,
            expand: true,
            loading: _booking,
            onPressed: _booking ? null : _book,
          ),
          const SizedBox(height: AtelierSpace.s8),
          Text(
            'Paid now from your wallet. Rejected or unreviewed ads are '
            'refunded in full; cancel any time before the first day.',
            textAlign: TextAlign.center,
            style: AtelierType.caption(p.muted),
          ),
          const SizedBox(height: AtelierSpace.s32),
        ],
      ],
    );
  }

  Widget _step(String n, String label) {
    final p = context.atelier;
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: p.onyx),
          child: Text(n, style: AtelierType.label(p.onOnyx, size: 11)),
        ),
        const SizedBox(width: 10),
        Text(label, style: AtelierType.title(p.ink)),
      ],
    );
  }

  Widget _datesCard(SpotlightRate rate) {
    final p = context.atelier;
    final start = _start;
    final end = _end;
    final short = _shortDays;
    final days = _availability;
    return AtelierCard(
      padding: const EdgeInsets.all(AtelierSpace.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtelierDateTile(
            label: 'First day',
            value: start == null ? null : maisonDayLabel(start),
            placeholder: 'Choose a date',
            error: _submitted && start == null,
            onTap: _pickStart,
          ),
          const SizedBox(height: AtelierSpace.s12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DAYS', style: AtelierType.overline(p.muted)),
                    const SizedBox(height: 4),
                    Text(
                      rate.minDays == rate.maxDays
                          ? '${rate.minDays} days'
                          : '${rate.minDays}–${rate.maxDays} days',
                      style: AtelierType.caption(p.muted),
                    ),
                  ],
                ),
              ),
              AtelierIconButton(
                icon: Icons.remove_rounded,
                tooltip: 'Fewer days',
                onPressed: _days > rate.minDays
                    ? () => _setDays(_days - 1)
                    : null,
              ),
              SizedBox(
                width: 52,
                child: Text(
                  '$_days',
                  textAlign: TextAlign.center,
                  style: AtelierType.figure(p.ink, size: 20),
                ),
              ),
              AtelierIconButton(
                icon: Icons.add_rounded,
                tooltip: 'More days',
                onPressed: _days < rate.maxDays
                    ? () => _setDays(_days + 1)
                    : null,
              ),
            ],
          ),
          if (start != null && end != null) ...[
            const SizedBox(height: AtelierSpace.s12),
            Text(
              'Runs ${spotlightRange(start, end)}, both days included.',
              style: AtelierType.caption(p.inkSoft, size: 12.5),
            ),
          ],
          if (_loadingAvailability) ...[
            const SizedBox(height: AtelierSpace.s12),
            const LinearProgressIndicator(minHeight: 2),
          ] else if (days != null && days.isNotEmpty) ...[
            const SizedBox(height: AtelierSpace.s12),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final d = days[i];
                  final full = short.contains(d);
                  final tone = full ? p.ruby : p.emerald;
                  return Container(
                    width: 52,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: tone.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AtelierRadius.xs),
                      border: Border.all(color: tone.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${d.date.day}/${d.date.month}',
                          style: AtelierType.caption(p.inkSoft, size: 11),
                        ),
                        Text(
                          '${d.free} free',
                          style: AtelierType.label(tone, size: 11),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (short.isNotEmpty) ...[
              const SizedBox(height: AtelierSpace.s8),
              Text(
                rate.isSponsoredProducts
                    ? 'Each product needs a free slot on every day. '
                          'Pick other days or fewer products.'
                    : 'Fully booked on some days. Pick other days.',
                style: AtelierType.caption(p.ruby),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _contentCard(SpotlightRate rate) {
    final p = context.atelier;
    if (rate.isFeaturedSeller) {
      return AtelierCard(
        padding: const EdgeInsets.all(AtelierSpace.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AtelierTextField(
              controller: _title,
              label: 'Tagline (optional)',
              hint: 'e.g. Certified diamonds, cut in Surat',
              error: _submitted ? _titleError : null,
              onChanged: (_) => setState(_changed),
            ),
            const SizedBox(height: AtelierSpace.s8),
            Text(
              'Your card shows your logo, cover, city and rating from your '
              'profile, which needs a company name.',
              style: AtelierType.caption(p.muted),
            ),
          ],
        ),
      );
    }
    if (rate.isSponsoredProducts) {
      return AtelierCard(
        padding: const EdgeInsets.all(AtelierSpace.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final product in _products)
              Padding(
                padding: const EdgeInsets.only(bottom: AtelierSpace.s8),
                child: Row(
                  children: [
                    AtelierThumb(url: product.imageUrl, size: 44),
                    const SizedBox(width: AtelierSpace.s12),
                    Expanded(
                      child: Text(
                        product.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AtelierType.label(p.ink),
                      ),
                    ),
                    AtelierIconButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Remove',
                      size: 32,
                      onPressed: () => setState(() {
                        _changed();
                        _products = [
                          for (final x in _products)
                            if (x.key != product.key) x,
                        ];
                      }),
                    ),
                  ],
                ),
              ),
            AtelierButton(
              label: _products.isEmpty ? 'Choose products' : 'Change products',
              icon: Icons.inventory_2_outlined,
              variant: AtelierButtonVariant.secondary,
              onPressed: _category == null ? null : _pickProducts,
            ),
            const SizedBox(height: AtelierSpace.s8),
            Text(
              'Up to ${rate.maxProducts}, all for sale and in this section. '
              'Priced per product per day.',
              style: AtelierType.caption(p.muted),
            ),
            if (_submitted && _products.isEmpty)
              const AtelierFieldError(error: 'Pick at least one product.'),
          ],
        ),
      );
    }
    // Banner.
    return AtelierCard(
      padding: const EdgeInsets.all(AtelierSpace.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtelierTextField(
            controller: _title,
            label: 'Title',
            hint: '2–60 characters',
            error: _submitted ? _titleError : null,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(_changed),
          ),
          const SizedBox(height: AtelierSpace.s12),
          AtelierTextField(
            controller: _subtitle,
            label: 'Subtitle (optional)',
            hint: 'Up to 120 characters',
            error: _submitted ? _subtitleError : null,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(_changed),
          ),
          const SizedBox(height: AtelierSpace.s16),
          _ImageSlot(
            label: 'Banner image · 4:1, 1600 × 400 px is ideal',
            aspect: 4,
            image: _image,
            uploading: _uploadingImage,
            error: _submitted && _image == null,
            onPick: () => _upload(mobile: false),
          ),
          const SizedBox(height: AtelierSpace.s12),
          _ImageSlot(
            label: 'Phone image (optional) · 2:1, such as 1200 × 600 px',
            aspect: 2,
            image: _mobileImage,
            uploading: _uploadingMobile,
            onPick: () => _upload(mobile: true),
            onClear: _mobileImage == null
                ? null
                : () => setState(() => _mobileImage = null),
          ),
          const SizedBox(height: AtelierSpace.s8),
          Text(
            'JPEG, PNG or WebP, up to 5 MB and at least 600 px wide.',
            style: AtelierType.caption(p.muted),
          ),
          const SizedBox(height: AtelierSpace.s16),
          Text('OPENS', style: AtelierType.overline(p.muted)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  _linkProduct == null
                      ? 'Your shop'
                      : 'Product: ${_linkProduct!.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.label(p.ink),
                ),
              ),
              if (_linkProduct != null)
                AtelierButton(
                  label: 'Shop instead',
                  compact: true,
                  variant: AtelierButtonVariant.ghost,
                  onPressed: () => setState(() => _linkProduct = null),
                ),
              AtelierButton(
                label: _linkProduct == null ? 'Pick product' : 'Change',
                compact: true,
                variant: AtelierButtonVariant.secondary,
                onPressed: _pickLinkProduct,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summary(SpotlightRate rate) {
    final p = context.atelier;
    final perUnit = rate.isSponsoredProducts
        ? '${maisonInr(rate.pricePerDay)} × $_days days × ${_products.length} '
              '${_products.length == 1 ? 'product' : 'products'}'
        : '${maisonInr(rate.pricePerDay)} × $_days days';
    final short = _o.availableBalance < _expected;
    return AtelierCard(
      padding: const EdgeInsets.all(AtelierSpace.s16),
      color: p.sunken,
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('TOTAL', style: AtelierType.overline(p.muted)),
              ),
              Text(
                maisonInr(_expected),
                style: AtelierType.display(p.ink, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(perUnit, style: AtelierType.caption(p.muted)),
          if (_quotedTotal != null) ...[
            const SizedBox(height: 6),
            Text(
              'The rate changed. This is the new total.',
              style: AtelierType.caption(p.amber),
            ),
          ],
          if (short) ...[
            const SizedBox(height: AtelierSpace.s8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Your wallet has ${maisonInr(_o.availableBalance)}.',
                    style: AtelierType.caption(p.ruby),
                  ),
                ),
                AtelierButton(
                  label: 'Top up',
                  compact: true,
                  variant: AtelierButtonVariant.secondary,
                  onPressed: () => context.push(AppRouteNames.sellerWallet),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RateCard extends StatelessWidget {
  const _RateCard({
    required this.rate,
    required this.selected,
    required this.onTap,
  });

  final SpotlightRate rate;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final unit = rate.isSponsoredProducts ? 'product' : 'ad';
    final days = rate.minDays == rate.maxDays
        ? '${rate.minDays} days'
        : '${rate.minDays}–${rate.maxDays} days';
    return AtelierCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AtelierSpace.s16),
      borderColor: selected ? p.gold : null,
      elevated: selected,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: selected ? p.gold : p.muted,
            size: 20,
          ),
          const SizedBox(width: AtelierSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rate.label, style: AtelierType.title(p.ink, size: 15)),
                if (rate.description != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    rate.description!,
                    style: AtelierType.caption(p.muted, size: 12.5),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  '$days · book up to ${rate.bookAheadDays} days ahead'
                  '${rate.slots > 0 ? ' · ${rate.slots} slots a day' : ''}',
                  style: AtelierType.caption(p.inkSoft, size: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: AtelierSpace.s8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                maisonInr(rate.pricePerDay),
                style: AtelierType.figure(p.ink, size: 15),
              ),
              Text(
                'per $unit / day',
                style: AtelierType.caption(p.muted, size: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Upload target for one banner image, previewed at its own ratio.
class _ImageSlot extends StatelessWidget {
  const _ImageSlot({
    required this.label,
    required this.aspect,
    required this.image,
    required this.uploading,
    required this.onPick,
    this.error = false,
    this.onClear,
  });

  final String label;
  final double aspect;
  final SpotlightCreative? image;
  final bool uploading;
  final bool error;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final img = image;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: AtelierType.caption(p.inkSoft, size: 12)),
        const SizedBox(height: 6),
        Pressable(
          onTap: uploading ? null : onPick,
          child: AspectRatio(
            aspectRatio: aspect,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: p.sunken,
                borderRadius: BorderRadius.circular(AtelierRadius.sm),
                border: Border.all(
                  color: error ? p.ruby : p.hairline,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (img != null)
                    AppNetworkImage(url: img.url, memCacheWidth: 1000),
                  if (img == null || uploading)
                    Center(
                      child: uploading
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: p.muted,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Upload',
                                  style: AtelierType.label(p.muted),
                                ),
                              ],
                            ),
                    ),
                  if (img != null && onClear != null && !uploading)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: AtelierIconButton(
                        icon: Icons.close_rounded,
                        tooltip: 'Remove',
                        size: 30,
                        filled: true,
                        onPressed: onClear!,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
