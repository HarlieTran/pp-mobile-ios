import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pantry_models.dart';
import '../services/pantry_service.dart';

/// ──────────────────────────────────────────────
/// Pantry Provider
/// Mirrors: pp-frontend ingredientsSlice
/// ──────────────────────────────────────────────

final pantryServiceProvider = Provider((_) => PantryService());

final pantryProvider =
    StateNotifierProvider<PantryNotifier, AsyncValue<List<PantryItem>>>(
  (ref) => PantryNotifier(ref.read(pantryServiceProvider)),
);

class PantryNotifier extends StateNotifier<AsyncValue<List<PantryItem>>> {
  final PantryService _service;

  PantryNotifier(this._service) : super(const AsyncValue.loading());

  Future<void> fetchItems() async {
    state = const AsyncValue.loading();
    try {
      final items = await _service.fetchItems();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addItem(AddPantryItemPayload payload) async {
    try {
      final item = await _service.addItem(payload);
      state = AsyncValue.data([...state.value ?? [], item]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateItem(String id, UpdatePantryItemPayload payload) async {
    try {
      final updated = await _service.updateItem(id, payload);
      final items = (state.value ?? [])
          .map((item) => item.id == id ? updated : item)
          .toList();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _service.deleteItem(id);
      final items =
          (state.value ?? []).where((item) => item.id != id).toList();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> bulkAddItems(List<AddPantryItemPayload> payloads) async {
    try {
      final newItems = await _service.bulkAddItems(payloads);
      state = AsyncValue.data([...state.value ?? [], ...newItems]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
