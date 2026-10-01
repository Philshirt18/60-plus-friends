import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/activity.dart';
import '../../core/models/interest.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatting.dart';
import '../../core/utils/photo_picker.dart';
import '../../core/widgets/interest_chip.dart';
import '../../core/widgets/photo_card.dart';
import '../../core/widgets/primary_button.dart';
import '../auth/auth_controller.dart';
import 'activities_controller.dart';

class CreateActivityScreen extends ConsumerStatefulWidget {
  const CreateActivityScreen({super.key, this.editing});

  /// When set, the screen edits this existing activity instead of creating
  /// a new one.
  final Activity? editing;

  @override
  ConsumerState<CreateActivityScreen> createState() =>
      _CreateActivityScreenState();
}

class _CreateActivityScreenState extends ConsumerState<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();

  DateTime? _date;
  TimeOfDay? _time;
  int _maxParticipants = 6;
  final Set<String> _interests = {};
  String? _photoUrl;
  bool _saving = false;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing != null) {
      _title.text = editing.title;
      _description.text = editing.description;
      _location.text = editing.approximateLocation;
      _date = DateTime(
          editing.dateTime.year, editing.dateTime.month, editing.dateTime.day);
      _time = TimeOfDay.fromDateTime(editing.dateTime);
      _maxParticipants = editing.maxParticipants;
      _interests.addAll(editing.interestIds);
      _photoUrl = editing.photoUrl;
      return;
    }
    final me = ref.read(currentUserProvider).valueOrNull;
    if (me != null && me.approximateArea.isNotEmpty) {
      _location.text = me.approximateArea;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 10, minute: 30),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickPhoto() async {
    final picked = await PhotoPicker.pick(context);
    if (picked != null && mounted) setState(() => _photoUrl = picked);
  }

  String _categoryLabel() {
    if (_interests.isEmpty) return 'Social';
    return _interests.map(InterestCatalog.nameOf).take(2).join(' · ');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null || _time == null) {
      _error('Please choose a date and time.');
      return;
    }
    final me = ref.read(currentUserProvider).valueOrNull;
    if (me == null) return;

    final dateTime = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );

    setState(() => _saving = true);
    final editing = widget.editing;
    final activity = Activity(
      id: editing?.id ?? '',
      creatorId: editing?.creatorId ?? me.id,
      title: _title.text.trim(),
      description: _description.text.trim(),
      category: _categoryLabel(),
      dateTime: dateTime,
      approximateLocation: _location.text.trim(),
      maxParticipants: _maxParticipants,
      interestIds: _interests.toList(),
      participantIds: editing?.participantIds ?? [me.id],
      createdAt: editing?.createdAt ?? DateTime.now(),
      photoUrl: _photoUrl,
    );

    final ctrl = ref.read(activitiesControllerProvider);
    if (_isEditing) {
      await ctrl.update(activity);
      if (!mounted) return;
      setState(() => _saving = false);
      context.pop();
    } else {
      final created = await ctrl.create(activity);
      if (!mounted) return;
      setState(() => _saving = false);
      context.pushReplacement('/activities/detail', extra: created);
    }
  }

  void _error(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(_isEditing ? 'Edit activity' : 'Create activity')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _label('Photo (optional)'),
                PhotoCard(
                  photoUrl: _photoUrl,
                  fallbackIcon: Icons.image_outlined,
                  height: 180,
                  onEdit: _pickPhoto,
                  editLabel: _photoUrl == null ? 'Add photo' : 'Change photo',
                ),
                const SizedBox(height: AppSpacing.md),
                _label('Title'),
                TextFormField(
                  controller: _title,
                  style: const TextStyle(fontSize: 18),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Sunday morning walk',
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Please add a title' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                _label('Description'),
                TextFormField(
                  controller: _description,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 18),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    alignLabelWithHint: true,
                    hintText:
                        "I'm going for a relaxed walk and would be happy to "
                        'have some company.',
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Please add a short description'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                _label('When'),
                Row(
                  children: [
                    Expanded(
                      child: _PickerTile(
                        icon: Icons.calendar_today,
                        label: _date == null
                            ? 'Choose date'
                            : Formatting.activityWhenShort(
                                    DateTime(_date!.year, _date!.month,
                                        _date!.day, 0, 0))
                                .split(' · ')
                                .first,
                        onTap: _pickDate,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _PickerTile(
                        icon: Icons.schedule,
                        label: _time == null
                            ? 'Choose time'
                            : _time!.format(context),
                        onTap: _pickTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _label('Approximate location'),
                TextFormField(
                  controller: _location,
                  style: const TextStyle(fontSize: 18),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.place_outlined),
                    hintText: 'e.g. Torre del Mar',
                    helperText: 'Use an area or landmark, never an exact address.',
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Please add an approximate location'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                _label('Maximum participants'),
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: _maxParticipants > 2
                          ? () => setState(() => _maxParticipants--)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Expanded(
                      child: Text(
                        '$_maxParticipants people',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: _maxParticipants < 20
                          ? () => setState(() => _maxParticipants++)
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _label('Related interests (optional)'),
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
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: _isEditing ? 'Save changes' : 'Create activity',
                  icon: Icons.check,
                  loading: _saving,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
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

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      child: Container(
        height: AppSpacing.minTouchTarget,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17)),
            ),
          ],
        ),
      ),
    );
  }
}
