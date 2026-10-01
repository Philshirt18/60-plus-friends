import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/subscription_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/state_views.dart';
import 'premium_controller.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  late Future<List<SubscriptionPackage>> _packagesFuture;
  String? _selectedId;
  bool _busy = false;

  static const _benefits = [
    ('See who is interested in you', Icons.visibility_outlined),
    ('Show interest in as many people as you like', Icons.all_inclusive),
    ('Widen your search to meet more people', Icons.travel_explore),
    ('Advanced discovery filters', Icons.tune),
    ('A gentle boost so more people see you', Icons.trending_up),
  ];

  @override
  void initState() {
    super.initState();
    _packagesFuture = ref.read(premiumControllerProvider).packages();
  }

  Future<void> _purchase() async {
    final packages = await _packagesFuture;
    final selected = packages.firstWhere(
      (p) => p.id == _selectedId,
      orElse: () => packages.first,
    );
    setState(() => _busy = true);
    try {
      final premium =
          await ref.read(premiumControllerProvider).purchase(selected);
      if (!mounted) return;
      setState(() => _busy = false);
      if (premium) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome to Premium!')),
        );
        context.pop();
      }
    } on PurchaseCancelled {
      if (mounted) setState(() => _busy = false);
      // User backed out — no message needed.
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not complete the purchase. Please try again.')),
      );
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    final premium = await ref.read(premiumControllerProvider).restore();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(premium
            ? 'Your Premium has been restored.'
            : 'No previous purchases found.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Premium',
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: _busy ? null : _restore,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Restore'),
          ),
        ],
      ),
      body: isPremium ? _alreadyPremium(context) : _paywall(context),
    );
  }

  Widget _alreadyPremium(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium,
                size: 72, color: AppColors.accent),
            const SizedBox(height: AppSpacing.md),
            Text("You're a Premium member",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Thank you for supporting the community. Enjoy all Premium '
              'features.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paywall(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const _Hero(),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ..._benefits.map((b) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryLight,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(b.$2,
                                    color: AppColors.primaryDark, size: 22),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(b.$1,
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ink)),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: AppSpacing.md),
                    FutureBuilder<List<SubscriptionPackage>>(
                      future: _packagesFuture,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(AppSpacing.lg),
                            child: LoadingView(),
                          );
                        }
                        final packages = snapshot.data!;
                        _selectedId ??= packages
                            .firstWhere((p) => p.highlighted,
                                orElse: () => packages.first)
                            .id;
                        return Column(
                          children: packages
                              .map((p) => _PackageTile(
                                    package: p,
                                    selected: p.id == _selectedId,
                                    onTap: () =>
                                        setState(() => _selectedId = p.id),
                                  ))
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              PrimaryButton(
                label: 'Start Premium',
                loading: _busy,
                onPressed: _purchase,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Cancel anytime in your app store settings.',
                style: TextStyle(fontSize: 14, color: AppColors.inkFaint),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 100, AppSpacing.lg, AppSpacing.xl),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium,
                size: 38, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Get more from your community',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.white)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Everything you love stays free. Premium simply helps you '
            'meet more people.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16, color: Colors.white.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({
    required this.package,
    required this.selected,
    required this.onTap,
  });
  final SubscriptionPackage package;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2.5 : 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected ? AppColors.primary : AppColors.inkFaint,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(package.title,
                            style: const TextStyle(
                                fontSize: 19, fontWeight: FontWeight.w700)),
                        if (package.highlighted) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Best value',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                    Text(package.period,
                        style: const TextStyle(
                            fontSize: 15, color: AppColors.inkSoft)),
                  ],
                ),
              ),
              Text(package.priceLabel,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}
