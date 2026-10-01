import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/app_user.dart';
import '../../core/models/interest.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/photo_picker.dart';
import '../../core/widgets/interest_chip.dart';
import '../../core/widgets/photo_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/state_views.dart';
import '../auth/auth_controller.dart';
import 'profile_controller.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _city = TextEditingController();
  final _area = TextEditingController();
  AgeRange? _ageRange;
  late Set<String> _interests;
  late Set<LookingFor> _lookingFor;
  String? _photoUrl;
  bool _loaded = false;
  bool _saving = false;

  void _load(AppUser me) {
    if (_loaded) return;
    _name.text = me.firstName;
    _bio.text = me.bio;
    _city.text = me.city;
    _area.text = me.approximateArea;
    _ageRange = me.ageRange;
    _interests = me.interests.toSet();
    _lookingFor = me.lookingFor.toSet();
    _photoUrl = me.profilePhotoUrl;
    _loaded = true;
  }

  Future<void> _pickPhoto() async {
    final picked = await PhotoPicker.pick(context);
    if (picked != null && mounted) {
      setState(() => _photoUrl = picked);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _city.dispose();
    _area.dispose();
    super.dispose();
  }

  Future<void> _save(AppUser me) async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your first name.')),
      );
      return;
    }
    setState(() => _saving = true);
    await ref.read(profileControllerProvider).save(
          me.copyWith(
            firstName: _name.text.trim(),
            bio: _bio.text.trim(),
            city: _city.text.trim(),
            approximateArea: _area.text.trim(),
            ageRange: _ageRange,
            interests: _interests.toList(),
            lookingFor: _lookingFor.toList(),
            profilePhotoUrl: _photoUrl,
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated.')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider).valueOrNull;
    if (me == null) {
      return const Scaffold(body: LoadingView());
    }
    _load(me);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            PhotoCard(
              photoUrl: _photoUrl,
              fallbackLabel: _name.text,
              onEdit: _pickPhoto,
              editLabel: _photoUrl == null ? 'Add photo' : 'Change photo',
            ),
            const SizedBox(height: AppSpacing.lg),
            _label('First name'),
            TextField(
              controller: _name,
              style: const TextStyle(fontSize: 18),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _label('Age'),
            DropdownButtonFormField<AgeRange>(
              initialValue: _ageRange,
              items: AgeRange.values
                  .map((a) => DropdownMenuItem(
                        value: a,
                        child: Text(a.label,
                            style: const TextStyle(fontSize: 18)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _ageRange = v),
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: AppSpacing.md),
            _label('City'),
            TextField(
              controller: _city,
              style: const TextStyle(fontSize: 18),
              decoration:
                  const InputDecoration(prefixIcon: Icon(Icons.location_city)),
            ),
            const SizedBox(height: AppSpacing.md),
            _label('Approximate area'),
            TextField(
              controller: _area,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.place_outlined),
                helperText: 'Never your exact address.',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _label('Short introduction'),
            TextField(
              controller: _bio,
              maxLines: 4,
              maxLength: 240,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(alignLabelWithHint: true),
            ),
            const SizedBox(height: AppSpacing.sm),
            _label('Interests'),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: InterestCatalog.all.map((i) {
                final selected = _interests.contains(i.id);
                return InterestChip(
                  label: i.name,
                  icon: i.icon,
                  compact: true,
                  selected: selected,
                  onTap: () => setState(() {
                    if (selected) {
                      _interests.remove(i.id);
                    } else {
                      _interests.add(i.id);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            _label('Looking for'),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: LookingFor.values.map((lf) {
                final selected = _lookingFor.contains(lf);
                return InterestChip(
                  label: lf.label,
                  compact: true,
                  selected: selected,
                  onTap: () => setState(() {
                    if (selected) {
                      _lookingFor.remove(lf);
                    } else {
                      _lookingFor.add(lf);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Save changes',
              icon: Icons.check,
              loading: _saving,
              onPressed: () => _save(me),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(text,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
      );
}
