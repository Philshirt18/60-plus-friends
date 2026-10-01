import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/activity.dart';
import '../../core/services/service_locator.dart';
import '../auth/auth_controller.dart';

/// Uploads a locally-picked activity photo (`file://...`) to storage when
/// available, returning the persisted download URL. Leaves already-remote or
/// asset references untouched, and gracefully falls back to the local path
/// if there is no storage backend (in-memory/dev mode).
Future<String?> resolveActivityPhoto(
  Ref ref, {
  required String activityId,
  required String? photoRef,
}) async {
  if (photoRef == null || !photoRef.startsWith('file://')) return photoRef;
  final storage = ref.read(storageServiceProvider);
  if (storage == null) return photoRef; // dev/mock: keep local path
  try {
    return await storage.uploadActivityPhoto(
      activityId: activityId,
      localPath: photoRef.substring('file://'.length),
    );
  } catch (_) {
    return photoRef; // upload failed — keep local path rather than lose it
  }
}

/// Filters for the activities list.
enum ActivityFilter {
  all('All'),
  today('Today'),
  thisWeek('This week'),
  nearby('Nearby'),
  myInterests('My interests');

  const ActivityFilter(this.label);
  final String label;
}

final activityFilterProvider =
    StateProvider<ActivityFilter>((ref) => ActivityFilter.all);

/// All activities from the repository.
final allActivitiesProvider = FutureProvider<List<Activity>>((ref) async {
  return ref.watch(dataRepositoryProvider).getActivities();
});

/// Activities after applying the selected filter (and never showing past ones).
final filteredActivitiesProvider = FutureProvider<List<Activity>>((ref) async {
  final activities = await ref.watch(allActivitiesProvider.future);
  final filter = ref.watch(activityFilterProvider);
  final me = ref.watch(currentUserProvider).valueOrNull;

  final now = DateTime.now().subtract(const Duration(hours: 3));
  var list = activities.where((a) => a.dateTime.isAfter(now)).toList();

  switch (filter) {
    case ActivityFilter.all:
      break;
    case ActivityFilter.today:
      list = list.where((a) => a.isToday()).toList();
    case ActivityFilter.thisWeek:
      list = list.where((a) => a.isThisWeek()).toList();
    case ActivityFilter.nearby:
      list = list
          .where((a) => (a.approxDistanceKm ?? 999) <= 10)
          .toList();
    case ActivityFilter.myInterests:
      final mine = me?.interests.toSet() ?? {};
      list = list
          .where((a) => a.interestIds.any(mine.contains))
          .toList();
  }
  return list;
});

/// Activities the current user has joined or created.
final myActivitiesProvider = FutureProvider<List<Activity>>((ref) async {
  final me = ref.watch(currentUserProvider).valueOrNull;
  if (me == null) return [];
  return ref.watch(dataRepositoryProvider).getActivitiesForUser(me.id);
});

final activityByIdProvider =
    FutureProvider.family<Activity?, String>((ref, id) async {
  return ref.watch(dataRepositoryProvider).getActivity(id);
});

class ActivitiesController {
  ActivitiesController(this._ref);
  final Ref _ref;

  Future<Activity> create(Activity activity) async {
    // Assign the id up front so a locally-picked photo can be uploaded keyed
    // by it right after creation.
    final id = activity.id.isEmpty ? const Uuid().v4() : activity.id;
    final repo = _ref.read(dataRepositoryProvider);
    var created = await repo.createActivity(_withActivityId(activity, id));

    final localPhoto = created.photoUrl;
    if (localPhoto != null && localPhoto.startsWith('file://')) {
      final uploaded = await resolveActivityPhoto(
        _ref,
        activityId: created.id,
        photoRef: localPhoto,
      );
      if (uploaded != null && uploaded != localPhoto) {
        created = await repo.updateActivityPhoto(created.id, uploaded);
      }
    }

    _refresh();
    return created;
  }

  Activity _withActivityId(Activity activity, String id) => Activity(
        id: id,
        creatorId: activity.creatorId,
        title: activity.title,
        description: activity.description,
        category: activity.category,
        dateTime: activity.dateTime,
        approximateLocation: activity.approximateLocation,
        maxParticipants: activity.maxParticipants,
        interestIds: activity.interestIds,
        participantIds: activity.participantIds,
        createdAt: activity.createdAt,
        photoUrl: activity.photoUrl,
      );

  Future<Activity> update(Activity activity) async {
    final repo = _ref.read(dataRepositoryProvider);
    var toSave = activity;
    final photo = activity.photoUrl;
    if (photo != null && photo.startsWith('file://')) {
      final uploaded = await resolveActivityPhoto(
        _ref,
        activityId: activity.id,
        photoRef: photo,
      );
      if (uploaded != null) toSave = activity.copyWith(photoUrl: uploaded);
    }
    final updated = await repo.updateActivity(toSave);
    _refresh();
    _ref.invalidate(activityByIdProvider(activity.id));
    return updated;
  }

  Future<void> delete(String activityId) async {
    await _ref.read(dataRepositoryProvider).deleteActivity(activityId);
    _refresh();
    _ref.invalidate(activityByIdProvider(activityId));
  }

  Future<void> join(String activityId) async {
    final me = _ref.read(currentUserProvider).valueOrNull;
    if (me == null) return;
    await _ref.read(dataRepositoryProvider).joinActivity(activityId, me.id);
    _refresh();
  }

  Future<void> leave(String activityId) async {
    final me = _ref.read(currentUserProvider).valueOrNull;
    if (me == null) return;
    await _ref.read(dataRepositoryProvider).leaveActivity(activityId, me.id);
    _refresh();
  }

  void _refresh() {
    _ref.invalidate(allActivitiesProvider);
    _ref.invalidate(myActivitiesProvider);
  }
}

final activitiesControllerProvider =
    Provider<ActivitiesController>(ActivitiesController.new);
