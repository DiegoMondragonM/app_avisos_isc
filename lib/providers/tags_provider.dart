import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tag.dart';
import '../services/tags_service.dart';

// Catálogo completo de tags
final catalogoTagsProvider = FutureProvider<List<Tag>>((ref) async {
  return TagsService.instance.getTags();
});

// Intereses del estudiante autenticado
final misInteresesProvider = FutureProvider<List<Tag>>((ref) async {
  return TagsService.instance.getMisIntereses();
});

// Selección temporal de intereses (onboarding / pantalla de edición)
class InteresesNotifier extends StateNotifier<Set<int>> {
  InteresesNotifier(super.initial);

  void toggle(int tagId) {
    if (state.contains(tagId)) {
      state = {...state}..remove(tagId);
    } else {
      state = {...state, tagId};
    }
  }

  void setAll(List<int> ids) => state = Set.from(ids);

  Future<void> guardar() async {
    await TagsService.instance.saveMisIntereses(state.toList());
  }
}

final interesesNotifierProvider =
    StateNotifierProvider<InteresesNotifier, Set<int>>(
  (_) => InteresesNotifier({}),
);
