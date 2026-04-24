import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile_models.dart';
import '../services/profile_service.dart';

/// ──────────────────────────────────────────────
/// Profile Provider
/// Mirrors: pp-frontend preferencesSlice (profile subset)
/// ──────────────────────────────────────────────

final profileServiceProvider = Provider((_) => ProfileService());

final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfile>>(
  (ref) => ProfileNotifier(ref.read(profileServiceProvider)),
);

class ProfileNotifier extends StateNotifier<AsyncValue<UserProfile>> {
  final ProfileService _service;

  ProfileNotifier(this._service) : super(const AsyncValue.loading());

  Future<void> fetchProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _service.fetchProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile(UpdateProfilePayload payload) async {
    try {
      await _service.updateProfile(payload);
      await fetchProfile();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
