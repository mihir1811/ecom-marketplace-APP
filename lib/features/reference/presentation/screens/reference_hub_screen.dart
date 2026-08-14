import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../application/reference_providers.dart';
import '../../domain/models/reference_models.dart';

/// Shared buyer/seller hub for referral code, request, inbound/outbound.
class ReferenceHubScreen extends ConsumerStatefulWidget {
  const ReferenceHubScreen({super.key});

  @override
  ConsumerState<ReferenceHubScreen> createState() => _ReferenceHubScreenState();
}

class _ReferenceHubScreenState extends ConsumerState<ReferenceHubScreen> {
  final _emailOrCodeCtrl = TextEditingController();
  var _submitting = false;

  @override
  void dispose() {
    _emailOrCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final value = _emailOrCodeCtrl.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an email or referral code')),
      );
      return;
    }
    setState(() => _submitting = true);
    final result =
        await ref.read(referenceHubProvider.notifier).request(value);
    if (!mounted) return;
    setState(() => _submitting = false);
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case Success():
        _emailOrCodeCtrl.clear();
        messenger.showSnackBar(
          const SnackBar(content: Text('Reference request sent')),
        );
      case ResultFailure(failure: final failure):
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(referenceHubProvider);
    final profile = state.profile;

    return RefreshIndicator(
      onRefresh: () => ref.read(referenceHubProvider.notifier).refresh(),
      child: state.isLoading && profile == null
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: CircularProgressIndicator()),
              ],
            )
          : state.errorMessage != null && profile == null
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.s24),
                  children: [
                    Text(state.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.s16),
                    Center(
                      child: FilledButton(
                        onPressed: () =>
                            ref.read(referenceHubProvider.notifier).refresh(),
                        child: const Text('Retry'),
                      ),
                    ),
                  ],
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                      ref
                          .read(referenceHubProvider.notifier)
                          .loadMorePurchases();
                    }
                    return false;
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      if (profile != null) _ProfileCard(profile: profile),
                      const SizedBox(height: 16),
                      _RequestCard(
                        controller: _emailOrCodeCtrl,
                        submitting: _submitting,
                        onSubmit: _submitRequest,
                        hasActiveOutbound: profile?.activeOutbound != null,
                      ),
                      const SizedBox(height: 16),
                      _SectionTitle(
                        'Inbound',
                        badge: profile?.inboundPendingCount,
                      ),
                      if (state.inbound.isEmpty)
                        const _EmptyNote('No inbound reference requests')
                      else
                        ...state.inbound.map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _InboundCard(request: r),
                          ),
                        ),
                      const SizedBox(height: 8),
                      const _SectionTitle('Outbound'),
                      if (state.outbound.isEmpty)
                        const _EmptyNote('No outbound reference requests')
                      else
                        ...state.outbound.map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _OutboundCard(request: r),
                          ),
                        ),
                      const SizedBox(height: 8),
                      const _SectionTitle('Referred purchases'),
                      if (state.purchases.isEmpty)
                        const _EmptyNote('No referred purchases yet')
                      else
                        ...state.purchases.map(
                          (p) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PurchaseCard(purchase: p),
                          ),
                        ),
                      if (state.isLoadingMorePurchases)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});

  final ReferenceProfile profile;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your referral code',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMutedLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  profile.referralCode,
                  style: AppTypography.title.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Copy code',
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: profile.referralCode),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Referral code copied')),
                  );
                },
                icon: const Icon(Icons.copy_outlined),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _StatChip(
                label: 'Pending inbound',
                value: '${profile.inboundPendingCount}',
              ),
              _StatChip(
                label: 'Accepted inbound',
                value: '${profile.inboundAcceptedCount}',
              ),
              _StatChip(
                label: 'Commission',
                value: AppCurrency.usd(profile.totalCommissionEarned),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.controller,
    required this.submitting,
    required this.onSubmit,
    required this.hasActiveOutbound,
  });

  final TextEditingController controller;
  final bool submitting;
  final VoidCallback onSubmit;
  final bool hasActiveOutbound;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Request a reference',
            style: AppTypography.label.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            hasActiveOutbound
                ? 'You already have a pending outbound request.'
                : 'Enter a referrer email or their referral code.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            enabled: !submitting && !hasActiveOutbound,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmit(),
            decoration: const InputDecoration(
              labelText: 'Email or referral code',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: submitting || hasActiveOutbound ? null : onSubmit,
            child: Text(submitting ? 'Sending…' : 'Send request'),
          ),
        ],
      ),
    );
  }
}

class _InboundCard extends ConsumerWidget {
  const _InboundCard({required this.request});

  final ReferenceRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.partyLabel,
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                request.status.label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.bronze,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (request.party?.email.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              request.party!.email,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMutedLight,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Requested ${request.createdAtLabel}',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMutedLight,
            ),
          ),
          if (request.status.isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final result = await ref
                          .read(referenceHubProvider.notifier)
                          .reject(request.id);
                      if (!context.mounted) return;
                      _toast(context, result, 'Request rejected');
                    },
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      final result = await ref
                          .read(referenceHubProvider.notifier)
                          .accept(request.id);
                      if (!context.mounted) return;
                      _toast(context, result, 'Request accepted');
                    },
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _toast(
    BuildContext context,
    Result<ReferenceRequest, Failure> result,
    String ok,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case Success():
        messenger.showSnackBar(SnackBar(content: Text(ok)));
      case ResultFailure(failure: final failure):
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }
}

class _OutboundCard extends StatelessWidget {
  const _OutboundCard({required this.request});

  final ReferenceRequest request;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.partyLabel,
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                request.status.label,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Sent ${request.createdAtLabel}',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  const _PurchaseCard({required this.purchase});

  final ReferencePurchase purchase;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  purchase.label,
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  purchase.createdAtLabel,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
          Text(
            purchase.amountLabel,
            style: AppTypography.label.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.badge});

  final String title;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Text(
            title,
            style: AppTypography.label.copyWith(fontWeight: FontWeight.w800),
          ),
          if (badge != null && badge! > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.bronze.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$badge',
                style: AppTypography.caption.copyWith(
                  color: AppColors.bronzeDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: AppColors.textMutedLight,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.sandSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMutedLight,
            ),
          ),
          Text(
            value,
            style: AppTypography.label.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warmBorder),
        boxShadow: AppShadows.cardLight,
      ),
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: child,
    );
  }
}
