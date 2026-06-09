import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/categorias/publicacion_categorizador.dart';
import '../core/storage/categorias_storage.dart';

/// Estado de las categorías seleccionadas por el usuario.
class CategoriasState {
  final List<String> seleccionadas;
  final bool cargado;

  const CategoriasState({
    this.seleccionadas = const [],
    this.cargado = false,
  });

  bool contiene(String categoria) => seleccionadas.contains(categoria);

  CategoriasState copyWith({
    List<String>? seleccionadas,
    bool? cargado,
  }) =>
      CategoriasState(
        seleccionadas: seleccionadas ?? this.seleccionadas,
        cargado: cargado ?? this.cargado,
      );
}

class CategoriasNotifier extends StateNotifier<CategoriasState> {
  CategoriasNotifier() : super(const CategoriasState());

  final _storage = CategoriasStorage.instance;

  /// Lee las categorías guardadas en el dispositivo.
  Future<void> cargar() async {
    final guardadas = await _storage.readCategorias();
    state = CategoriasState(seleccionadas: guardadas, cargado: true);
  }

  /// Persiste una nueva lista de categorías seleccionadas.
  Future<void> guardar(List<String> categorias) async {
    await _storage.saveCategorias(categorias);
    state = state.copyWith(seleccionadas: categorias, cargado: true);
  }

  /// Agrega o quita una categoría de la selección en memoria (sin persistir).
  void toggle(String categoria) {
    final nuevas = List<String>.from(state.seleccionadas);
    if (nuevas.contains(categoria)) {
      nuevas.remove(categoria);
    } else {
      nuevas.add(categoria);
    }
    state = state.copyWith(seleccionadas: nuevas);
  }

  /// Selecciona todas las categorías disponibles.
  void seleccionarTodas() {
    state = state.copyWith(seleccionadas: List.from(todasLasCategorias));
  }

  /// Limpia la selección.
  void limpiar() {
    state = state.copyWith(seleccionadas: []);
  }
}

final categoriasProvider =
    StateNotifierProvider<CategoriasNotifier, CategoriasState>(
  (_) => CategoriasNotifier(),
);
