import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_user.dart';
import '../../core/models/interest.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/photo_picker.dart';
import '../../core/widgets/brand_mark.dart';
import '../../core/widgets/interest_chip.dart';
import '../../core/widgets/photo_card.dart';
import '../../core/widgets/primary_button.dart';
import 'onboarding_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  static const _lastPage = 5;

  final _cityCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _countryCtrl = TextEditingController(text: 'Spain');
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _saving = false;

  // Guards against a second tap re-triggering nextPage()/previousPage()
  // while the 250ms page-turn animation is still in flight, which could
  // otherwise skip or briefly flash a step out of order.
  bool _animating = false;

  @override
  void dispose() {
    _controller.dispose();
    _cityCtrl.dispose();
    _areaCtrl.dispose();
    _countryCtrl.dispose();
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_animating || _page >= _lastPage) return;
    _animating = true;
    await _controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    _animating = false;
  }

  Future<void> _back() async {
    if (_animating || _page <= 0) return;
    _animating = true;
    await _controller.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    _animating = false;
  }

  bool _canContinue(OnboardingDraft draft) {
    switch (_page) {
      case 0:
        return true;
      case 1:
        return draft.ageRange != null;
      case 2:
        return _countryCtrl.text.trim().isNotEmpty &&
            _cityCtrl.text.trim().isNotEmpty &&
            _areaCtrl.text.trim().isNotEmpty;
      case 3:
        return draft.interests.isNotEmpty;
      case 4:
        return draft.lookingFor.isNotEmpty;
      case 5:
        return _nameCtrl.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _pickPhoto() async {
    final picked = await PhotoPicker.pick(context);
    if (picked != null && mounted) {
      ref.read(onboardingControllerProvider.notifier).setProfile(photoUrl: picked);
    }
  }

  Future<void> _finish() async {
    final ctrl = ref.read(onboardingControllerProvider.notifier);
    ctrl.setLocation(
      country: _countryCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      area: _areaCtrl.text.trim(),
    );
    ctrl.setProfile(firstName: _nameCtrl.text, bio: _bioCtrl.text);
    setState(() => _saving = true);
    try {
      await ctrl.finish();
      // Router redirects to Discover once profile exists.
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: _page > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _animating ? null : _back,
                tooltip: 'Back',
              )
            : null,
        title: Text('Step ${_page + 1} of ${_lastPage + 1}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ProgressBar(value: (_page + 1) / (_lastPage + 1)),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _welcomeStep(),
                  _ageStep(draft),
                  _locationStep(),
                  _interestsStep(draft),
                  _lookingForStep(draft),
                  _profileStep(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: PrimaryButton(
                label: _page == _lastPage ? 'Finish' : 'Continue',
                icon: _page == _lastPage ? Icons.check : Icons.arrow_forward,
                loading: _saving,
                onPressed: (!_animating && _canContinue(draft))
                    ? (_page == _lastPage ? _finish : _next)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 1
  Widget _welcomeStep() {
    return _StepScroll(
      children: [
        const SizedBox(height: AppSpacing.lg),
        const BrandMark(size: 104),
        const SizedBox(height: AppSpacing.lg),
        Text('Welcome', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: AppSpacing.md),
        Text(
          "Let's set up your profile so you can meet people nearby who share "
          'your interests, and find activities to enjoy together.',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: AppColors.inkSoft),
        ),
      ],
    );
  }

  // Step 2
  Widget _ageStep(OnboardingDraft draft) {
    return _StepScroll(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepTitle('Your age', 'This helps us suggest people of a similar age.'),
        const SizedBox(height: AppSpacing.md),
        ...AgeRange.values.map((age) {
          final selected = draft.ageRange == age;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _SelectableTile(
              label: age.label,
              selected: selected,
              onTap: () => ref
                  .read(onboardingControllerProvider.notifier)
                  .setAge(age),
            ),
          );
        }),
      ],
    );
  }

  // Step 3
  Widget _locationStep() {
    return _StepScroll(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepTitle('Where are you?',
            'We only ever show your city and approximate area — never your exact address.'),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _countryCtrl,
          style: const TextStyle(fontSize: 18),
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Country',
            prefixIcon: Icon(Icons.public),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _cityCtrl,
          style: const TextStyle(fontSize: 18),
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'City',
            prefixIcon: Icon(Icons.location_city),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _areaCtrl,
          style: const TextStyle(fontSize: 18),
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Approximate area',
            hintText: 'e.g. Torre del Mar',
            prefixIcon: Icon(Icons.place_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const _PrivacyNote(
          'Your exact location is never shared with anyone.',
        ),
      ],
    );
  }

  // Step 4
  Widget _interestsStep(OnboardingDraft draft) {
    return _StepScroll(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle('Your interests',
            'Pick a few things you enjoy. You can change these later.'),
        const SizedBox(height: AppSpacing.md),
        ...InterestCategory.values.map((cat) {
          final items = InterestCatalog.byCategory(cat);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    top: AppSpacing.md, bottom: AppSpacing.sm),
                child: Text(cat.label,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: items.map((i) {
                  final selected = draft.interests.contains(i.id);
                  return InterestChip(
                    label: i.name,
                    icon: i.icon,
                    selected: selected,
                    onTap: () => ref
                        .read(onboardingControllerProvider.notifier)
                        .toggleInterest(i.id),
                  );
                }).toList(),
              ),
            ],
          );
        }),
      ],
    );
  }

  // Step 5
  Widget _lookingForStep(OnboardingDraft draft) {
    return _StepScroll(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepTitle('What are you looking for?',
            'Choose all that apply.'),
        const SizedBox(height: AppSpacing.md),
        ...LookingFor.values.map((lf) {
          final selected = draft.lookingFor.contains(lf);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _SelectableTile(
              label: lf.label,
              selected: selected,
              trailing: selected
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : const Icon(Icons.circle_outlined,
                      color: AppColors.inkFaint),
              onTap: () => ref
                  .read(onboardingControllerProvider.notifier)
                  .toggleLookingFor(lf),
            ),
          );
        }),
      ],
    );
  }

  // Step 6
  Widget _profileStep() {
    return _StepScroll(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepTitle('Your profile',
            'A friendly first name and a short introduction go a long way.'),
        const SizedBox(height: AppSpacing.md),
        PhotoCard(
          photoUrl: ref.watch(onboardingControllerProvider).photoUrl,
          fallbackLabel: _nameCtrl.text,
          onEdit: _pickPhoto,
          editLabel: ref.watch(onboardingControllerProvider).photoUrl == null
              ? 'Add photo'
              : 'Change photo',
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _nameCtrl,
          style: const TextStyle(fontSize: 18),
          onChanged: (_) => setState(() {}),
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'First name',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _bioCtrl,
          style: const TextStyle(fontSize: 18),
          maxLines: 4,
          maxLength: 240,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Short introduction',
            alignLabelWithHint: true,
            hintText:
                "I enjoy walking, gardening and discovering new places. I'd "
                'love to meet people nearby for coffee or a walk.',
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value),
          duration: const Duration(milliseconds: 250),
          builder: (_, v, __) => LinearProgressIndicator(
            value: v,
            minHeight: 8,
            backgroundColor: AppColors.border,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _StepScroll extends StatelessWidget {
  const _StepScroll({
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(crossAxisAlignment: crossAxisAlignment, children: children),
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle(this.title, this.subtitle);
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.inkSoft)),
      ],
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints:
              const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.primaryDark : AppColors.ink,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: AppColors.accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 16, color: AppColors.ink)),
          ),
        ],
      ),
    );
  }
}
