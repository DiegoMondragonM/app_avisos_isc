import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/categorias/publicacion_categorizador.dart';
import '../models/publicacion.dart';
import '../models/tag.dart';
import '../services/publicaciones_service.dart';
import '../services/sync_service.dart';

// ---- Feed online con filtros ----

class FeedParams {
  final String? tipo;
  final String? tag;
  final int page;
  final int limit;

  const FeedParams({
    this.tipo,
    this.tag,
    this.page = 1,
    this.limit = 20,
  });

  FeedParams copyWith({
    String? tipo,
    String? tag,
    int? page,
    int? limit,
  }) =>
      FeedParams(
        tipo: tipo ?? this.tipo,
        tag: tag ?? this.tag,
        page: page ?? this.page,
        limit: limit ?? this.limit,
      );

  FeedParams clearTipo() =>
      FeedParams(tag: tag, page: page, limit: limit);

  FeedParams clearTag() =>
      FeedParams(tipo: tipo, page: page, limit: limit);
}

class FeedState {
  final List<Publicacion> publicaciones;
  final int total;
  final int paginas;
  final bool isLoading;

  /// true mientras se carga la siguiente página (append, no reemplaza la lista)
  final bool isLoadingMore;

  final String? error;
  final FeedParams params;

  /// Slugs de los intereses del usuario actualmente aplicados al feed.
  /// Lista vacía = sin filtro de intereses (se muestra todo).
  final List<String> interesesActivos;

  const FeedState({
    this.publicaciones = const [],
    this.total = 0,
    this.paginas = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.params = const FeedParams(),
    this.interesesActivos = const [],
  });

  bool get filtraPorIntereses => interesesActivos.isNotEmpty;

  /// true si la API aún tiene páginas por cargar
  bool get hayMas => params.page < paginas;

  FeedState copyWith({
    List<Publicacion>? publicaciones,
    int? total,
    int? paginas,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    FeedParams? params,
    List<String>? interesesActivos,
  }) =>
      FeedState(
        publicaciones: publicaciones ?? this.publicaciones,
        total: total ?? this.total,
        paginas: paginas ?? this.paginas,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: error,
        params: params ?? this.params,
        interesesActivos: interesesActivos ?? this.interesesActivos,
      );
}

class FeedNotifier extends StateNotifier<FeedState> {
  FeedNotifier() : super(const FeedState());

  final _service = PublicacionesService.instance;
  final _sync = SyncService.instance;

  /// Filtra por intersección del periodo del curso con la ventana ±2 meses.
  static List<Publicacion> _aplicarRango(List<Publicacion> lista) =>
      lista.where((p) => p.intersectaVentanaActual()).toList();

  /// Carga el feed desde la API (filtros: tipo, tag individual).
  Future<void> cargar({FeedParams? params}) async {
    final p = params ?? state.params;
    state = state.copyWith(
      isLoading: true,
      error: null,
      params: p,
      interesesActivos: [],
    );
    try {
      final result = await _service.getPublicaciones(
        tipo: p.tipo,
        tag: p.tag,
        page: p.page,
        limit: p.limit,
      );
      state = state.copyWith(
        publicaciones: _aplicarRango(result.publicaciones),
        total: result.total,
        paginas: result.paginas,
        isLoading: false,
      );
    } catch (e) {
      final local = await _sync.getPublicacionesLocales();
      state = state.copyWith(
        publicaciones: _aplicarRango(local),
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Carga la siguiente página y la agrega al final de la lista actual.
  /// No hace nada si ya hay una carga en curso o no hay más páginas.
  Future<void> cargarMas() async {
    if (state.isLoading || state.isLoadingMore || !state.hayMas) return;
    if (state.filtraPorIntereses) return;

    final nextPage = state.params.page + 1;
    final p = state.params.copyWith(page: nextPage);

    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final result = await _service.getPublicaciones(
        tipo: p.tipo,
        tag: p.tag,
        page: p.page,
        limit: p.limit,
      );
      state = state.copyWith(
        publicaciones: [
          ...state.publicaciones,
          ..._aplicarRango(result.publicaciones),
        ],
        total: result.total,
        paginas: result.paginas,
        params: p,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  /// Carga el feed filtrado por los intereses del usuario (caché local).
  /// Usa los tag slugs para filtrar publicaciones con cualquiera de esos tags.
  Future<void> cargarConIntereses(List<Tag> intereses) async {
    if (intereses.isEmpty) {
      await cargar();
      return;
    }

    final slugs = intereses.map((t) => t.slug).toList();

    state = state.copyWith(
      isLoading: true,
      error: null,
      interesesActivos: slugs,
      params: const FeedParams(),
    );

    try {
      // Intentar primero en caché local (multi-tag, sin límite de la API)
      final local = await _sync.getPublicacionesPorIntereses(slugs);

      if (local.isNotEmpty) {
        state = state.copyWith(
          publicaciones: local,
          total: local.length,
          isLoading: false,
          interesesActivos: slugs,
        );
        return;
      }

      // Si la caché está vacía, usar el primer interés en la API online
      final result = await _service.getPublicaciones(
        tag: slugs.first,
        limit: 50,
      );
      state = state.copyWith(
        publicaciones: result.publicaciones,
        total: result.total,
        paginas: result.paginas,
        isLoading: false,
        interesesActivos: slugs,
      );
    } catch (e) {
      state = state.copyWith(
        publicaciones: [],
        isLoading: false,
        error: e.toString(),
        interesesActivos: slugs,
      );
    }
  }

  /// Sincroniza la caché local y recarga el feed actual.
  Future<void> sincronizar() async {
    try {
      await _sync.sync();
    } catch (_) {}
  }

  /// Quita el filtro de intereses y muestra todo.
  Future<void> verTodo() => cargar(params: const FeedParams());
}

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>(
  (_) => FeedNotifier(),
);

// ---- Sección "Para ti" (filtrado local por categorías de interés) -----------

class ParaTiState {
  final List<Publicacion> publicaciones;
  final bool isLoading;
  final String? error;

  /// true cuando el usuario aún no eligió ninguna categoría de interés
  final bool sinCategorias;

  const ParaTiState({
    this.publicaciones = const [],
    this.isLoading = false,
    this.error,
    this.sinCategorias = false,
  });

  ParaTiState copyWith({
    List<Publicacion>? publicaciones,
    bool? isLoading,
    String? error,
    bool? sinCategorias,
  }) =>
      ParaTiState(
        publicaciones: publicaciones ?? this.publicaciones,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        sinCategorias: sinCategorias ?? this.sinCategorias,
      );
}

/// Par: publicación + puntaje total de coincidencias con las categorías elegidas.
typedef _ScoredPub = ({Publicacion pub, int score});

class ParaTiNotifier extends StateNotifier<ParaTiState> {
  ParaTiNotifier() : super(const ParaTiState());

  final _sync = SyncService.instance;
  final _service = PublicacionesService.instance;
  final _cat = PublicacionCategorizador.instance;

  /// Filtra publicaciones de la caché local según las [categorias] elegidas
  /// por el usuario, usando scoring por palabras clave.
  ///
  /// Si la caché está vacía, descarga la primera página de la API y
  /// aplica el mismo filtro sobre esos resultados.
  Future<void> cargar(List<String> categorias) async {
    if (categorias.isEmpty) {
      state = const ParaTiState(sinCategorias: true);
      return;
    }

    state = const ParaTiState(isLoading: true);

    try {
      List<Publicacion> pool = await _sync.getPublicacionesLocales();

      // Si la caché está vacía, cargar desde la API (sin filtros)
      if (pool.isEmpty) {
        final result = await _service.getPublicaciones(limit: 50);
        pool = result.publicaciones;
      }

      // Para publicaciones manuales (admin): descartar las vencidas/eliminadas.
      // Las de MOOC se muestran siempre (son cursos permanentes sin fecha real).
      pool = pool.where((p) {
        if (p.fuente.toLowerCase() == 'mooc') return true;
        return p.isVigente;
      }).toList();

      // Filtro temporal: periodo del curso debe intersectar la ventana ±2 meses.
      pool = pool.where((p) => p.intersectaVentanaActual()).toList();

      const _catIdiomas = 'Idiomas y Cultura';
      final usuarioQuiereIdiomas = categorias.contains(_catIdiomas);

      bool esManual(Publicacion p) => p.fuente.toLowerCase() == 'manual';

      int compararPorFecha(Publicacion a, Publicacion b) {
        final da = a.fechaInicio ?? a.createdAt ?? DateTime(0);
        final db = b.fechaInicio ?? b.createdAt ?? DateTime(0);
        return db.compareTo(da);
      }

      bool tituloExcluido(Publicacion p) => _cat.excluirDeParaTi(
            p.titulo,
            usuarioQuiereIdiomas: usuarioQuiereIdiomas,
          );

      void ordenarPorScore(List<_ScoredPub> lista) {
        lista.sort((a, b) {
          final sp = b.score.compareTo(a.score);
          if (sp != 0) return sp;
          return compararPorFecha(a.pub, b.pub);
        });
      }

      // 1° Bloque: manuales (admin), todas, sin filtro de categorías.
      final manuales = pool
          .where((p) => esManual(p) && !tituloExcluido(p))
          .toList()
        ..sort(compararPorFecha);

      // 2° Coinciden con intereses (categoría principal del usuario).
      // 3° Por relevancia (coincidencia secundaria, menor prioridad).
      final coincidenIntereses = <_ScoredPub>[];
      final porRelevancia = <_ScoredPub>[];

      for (final pub in pool) {
        if (esManual(pub) || tituloExcluido(pub)) continue;

        final resultado = _cat.categorizar(pub.titulo, pub.descripcion);

        if (resultado.todas.contains(_catIdiomas) && !usuarioQuiereIdiomas) {
          continue;
        }

        final score = categorias.fold<int>(
          0,
          (sum, cat) => sum + (resultado.scores[cat] ?? 0),
        );

        if (!resultado.perteneceA(categorias)) continue;

        if (categorias.contains(resultado.principal)) {
          coincidenIntereses.add((pub: pub, score: score));
        } else {
          porRelevancia.add((pub: pub, score: score));
        }
      }

      ordenarPorScore(coincidenIntereses);
      ordenarPorScore(porRelevancia);

      state = ParaTiState(
        publicaciones: [
          ...manuales,
          ...coincidenIntereses.map((e) => e.pub),
          ...porRelevancia.map((e) => e.pub),
        ],
      );
    } catch (e) {
      state = ParaTiState(error: e.toString());
    }
  }
}

final paraTiProvider =
    StateNotifierProvider<ParaTiNotifier, ParaTiState>(
  (_) => ParaTiNotifier(),
);

// ---- Detalle de publicación ----

final detallePublicacionProvider =
    FutureProvider.family<Publicacion, int>((ref, id) async {
  try {
    return await PublicacionesService.instance.getDetalle(id);
  } catch (_) {
    final local = await SyncService.instance.getPublicacionLocal(id);
    if (local == null) rethrow;
    return local;
  }
});
