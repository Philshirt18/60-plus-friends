import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/app_user.dart';
import '../../core/models/social_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/image_source.dart';
import '../../core/widgets/category_chip.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/state_views.dart';
import '../auth/auth_controller.dart';
import '../premium/premium_controller.dart';
import 'discover_controller.dart';
import 'widgets/person_summary.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider).valueOrNull;
    final candidatesAsync = ref.watch(discoverProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium_outlined),
            tooltip: 'Premium',
            onPressed: () => context.push('/premium'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (me != null) _LocalityHeader(area: me.approximateArea),
            Expanded(
              child: candidatesAsync.when(
                loading: () => const LoadingView(
                    message: 'Finding people near you...'),
                error: (_, __) => ErrorView(
                  message: 'We could not load people right now.',
                  onRetry: () => ref.invalidate(discoverProvider),
                ),
                data: (candidates) {
                  if (me == null) return const LoadingView();
                  if (candidates.isEmpty) {
                    return EmptyState(
                      icon: Icons.groups_2_outlined,
                      title: "We're still finding people near you",
                      message:
                          'Invite someone you know to join the community, or '
                          'check back soon as more people join.',
                      actionLabel: 'Invite someone',
                      onAction: () => context.push('/invite'),
                    );
                  }
                  return _DiscoverDeck(me: me, candidates: candidates);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalityHeader extends StatelessWidget {
  const _LocalityHeader({required this.area});
  final String area;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.place, color: AppColors.primary, size: 22),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              area.isEmpty ? 'People near you' : 'People near $area',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverDeck extends ConsumerStatefulWidget {
  const _DiscoverDeck({required this.me, required this.candidates});
  final AppUser me;
  final List<AppUser> candidates;

  @override
  ConsumerState<_DiscoverDeck> createState() => _DiscoverDeckState();
}

class _DiscoverDeckState extends ConsumerState<_DiscoverDeck> {
  int _index = 0;
  bool _busy = false;

  AppUser? get _current =>
      _index < widget.candidates.length ? widget.candidates[_index] : null;

  Future<void> _onInterested(AppUser person) async {
    if (_busy) return;

    final isPremium = ref.read(isPremiumProvider);
    final used = ref.read(dailyInterestCounterProvider);
    if (!isPremium && used >= kFreeDailyInterests) {
      _showLimitReached();
      return;
    }

    setState(() => _busy = true);
    final match =
        await ref.read(discoverControllerProvider).expressInterest(person.id);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _index++;
    });

    if (match != null) {
      _openMatch(match, person);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You showed interest in ${person.firstName}.')),
      );
    }
  }

  Future<void> _onPass(AppUser person) async {
    if (_busy) return;
    setState(() => _busy = true);
    await ref.read(discoverControllerProvider).pass(person.id);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _index++;
    });
  }

  void _openMatch(Match match, AppUser person) {
    context.push('/match', extra: {'match': match, 'person': person});
  }

  void _showLimitReached() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium,
                size: 48, color: AppColors.accent),
            const SizedBox(height: AppSpacing.md),
            Text("You've reached today's free limit",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'You can show interest in more people today with Premium, or '
              'come back tomorrow.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, color: AppColors.inkSoft),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/premium');
                },
                child: const Text('See Premium'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final person = _current;
    if (person == null) {
      return EmptyState(
        icon: Icons.check_circle_outline,
        title: "That's everyone for now",
        message:
            "You've seen everyone nearby today. New people join all the time — "
            'check back soon, or create an activity to bring people together.',
        actionLabel: 'Create an activity',
        onAction: () => context.push('/activities/create'),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _PersonCard(
              me: widget.me,
              person: person,
              onTap: () => context.push('/person', extra: person),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Not for me',
                  icon: Icons.close,
                  color: AppColors.inkSoft,
                  filled: false,
                  onPressed: _busy ? null : () => _onPass(person),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ActionButton(
                  label: 'Interested',
                  icon: Icons.waving_hand,
                  color: AppColors.primary,
                  filled: true,
                  onPressed: _busy ? null : () => _onInterested(person),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.me,
    required this.person,
    required this.onTap,
  });
  final AppUser me;
  final AppUser person;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shared = sharedInterestNames(me, person);
    final looking = person.lookingFor.map((e) => e.label).toList();
    final photo = imageProviderFor(person.profilePhotoUrl);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PhotoHeader(person: person, photo: photo),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${person.firstName}, ${person.ageRange.midpoint}',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: person.interests
                          .take(4)
                          .map((id) => CategoryChip.interest(id))
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        const Icon(Icons.handshake_outlined,
                            size: 20, color: AppColors.inkSoft),
                        const SizedBox(width: 6),
                        const Text('Looking for',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkSoft)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      looking.join(' · '),
                      style: const TextStyle(
                          fontSize: 17,
                          color: AppColors.ink,
                          fontWeight: FontWeight.w500),
                    ),
                    if (person.bio.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          person.bio,
                          style: const TextStyle(
                            fontSize: 17,
                            height: 1.45,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                    if (shared.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          const Icon(Icons.favorite,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'You both enjoy ${shared.take(2).map((s) => s.toLowerCase()).join(' and ')}',
                              style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The photo (or gradient fallback) header with Online + distance badges.
class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({required this.person, required this.photo});
  final AppUser person;
  final ImageProvider? photo;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photo != null)
            Image(image: photo!, fit: BoxFit.cover)
          else
            _GradientFallback(name: person.firstName),
          // Soft gradient at the bottom for future overlay legibility.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x14000000)],
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.md,
            left: AppSpacing.md,
            child: _Badge(
              icon: Icons.circle,
              iconColor: AppColors.online,
              label: 'Online',
              iconSize: 12,
            ),
          ),
          if (person.approxDistanceKm != null)
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: _Badge(
                icon: Icons.place,
                iconColor: AppColors.primary,
                label: '${person.approxDistanceKm!.round()} km away',
              ),
            ),
        ],
      ),
    );
  }
}

class _GradientFallback extends StatelessWidget {
  const _GradientFallback({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.accentLight],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            fontSize: 84,
            fontWeight: FontWeight.w800,
            color: AppColors.primary),
      ),
    );
  }
}

/// A frosted white pill badge shown over photos.
class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.iconSize = 16,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: iconColor),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.filled,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 8),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );

    const shape = StadiumBorder();

    if (filled) {
      return SizedBox(
        height: 62,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: shape,
            elevation: 4,
            shadowColor: color.withValues(alpha: 0.45),
          ),
          child: child,
        ),
      );
    }
    return SizedBox(
      height: 62,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          backgroundColor: AppColors.background,
          side: BorderSide(color: AppColors.border, width: 1.5),
          shape: shape,
        ),
        child: child,
      ),
    );
  }
}
