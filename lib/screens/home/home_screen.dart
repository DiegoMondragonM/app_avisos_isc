import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/categorias_provider.dart';
import '../../providers/publicaciones_provider.dart';
import '../../widgets/publicacion_card.dart';
import '../../models/publicacion.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  // Scroll controllers por tab
  final _scrollTodos = ScrollController();
  bool _showFab = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(_onTabChange);
    _scrollTodos.addListener(_onScrollTodos);
    Future.microtask(_cargarTodo);
  }

  @override
  void dispose() {
    _tabCtrl.removeListener(_onTabChange);
    _tabCtrl.dispose();
    _scrollTodos.removeListener(_onScrollTodos);
    _scrollTodos.dispose();
    super.dispose();
  }

  void _onTabChange() => setState(() {}); // re-render para mostrar/ocultar FAB

  void _onScrollTodos() {
    final pos = _scrollTodos.position;

    final shouldShow = pos.pixels > 300;
    if (shouldShow != _showFab) setState(() => _showFab = shouldShow);

    // Cargar siguiente página al llegar al 90 % del scroll
    if (pos.pixels >= pos.maxScrollExtent * 0.9) {
      ref.read(feedProvider.notifier).cargarMas();
    }
  }

  Future<void> _cargarTodo() async {
    // Sincronizar caché local y cargar categorías del usuario
    await Future.wait([
      ref.read(feedProvider.notifier).sincronizar(),
      ref.read(categoriasProvider.notifier).cargar(),
    ]);
    // Cargar los dos tabs en paralelo
    await Future.wait([_cargarTodos(), _cargarParaTi()]);
  }

  Future<void> _cargarTodos() async {
    if (_scrollTodos.hasClients) _scrollTodos.jumpTo(0);
    await ref.read(feedProvider.notifier).cargar(params: const FeedParams());
  }

  Future<void> _cargarParaTi() async {
    // Lee siempre el estado actual del provider (ya actualizado por guardar())
    final categorias = ref.read(categoriasProvider).seleccionadas;
    await ref.read(paraTiProvider.notifier).cargar(categorias);
  }

  void _irAlInicio() {
    _scrollTodos.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cada vez que el usuario guarda nuevas categorías, recarga "Para ti"
    // automáticamente sin depender del timing de la navegación.
    ref.listen<CategoriasState>(categoriasProvider, (prev, next) {
      if (prev != null &&
          next.cargado &&
          prev.seleccionadas.toString() != next.seleccionadas.toString()) {
        _cargarParaTi();
      }
    });

    final authState = ref.watch(authProvider);
    final usuario =
        authState is AuthAuthenticated ? authState.usuario : null;

    final estaEnTodos = _tabCtrl.index == 1;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Avisos ISC',
                style: TextStyle(fontWeight: FontWeight.bold)),
            if (usuario != null)
              Text(
                'Hola, ${usuario.nombre.split(' ').first}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.interests_outlined),
            tooltip: 'Mis intereses',
            onPressed: () => context.push('/intereses'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(icon: Icon(Icons.favorite_outline), text: 'Para ti'),
            Tab(icon: Icon(Icons.list_rounded), text: 'Todos'),
          ],
        ),
      ),
      floatingActionButton: estaEnTodos && _showFab
          ? FloatingActionButton.small(
              onPressed: _irAlInicio,
              tooltip: 'Ir al inicio',
              child: const Icon(Icons.arrow_upward_rounded),
            )
          : null,
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // ── Tab "Para ti" ─────────────────────────────────────────
          _ParaTiTab(onRefresh: _cargarParaTi),
          // ── Tab "Todos" ───────────────────────────────────────────
          _TodosTab(
            scrollController: _scrollTodos,
            onRefresh: _cargarTodos,
          ),
        ],
      ),
    );
  }
}

// ─── Tab "Para ti" ────────────────────────────────────────────────────────────

class _ParaTiTab extends ConsumerWidget {
  final Future<void> Function() onRefresh;

  const _ParaTiTab({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paraTiProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.sinCategorias) {
      return _SinInteresesState();
    }

    if (state.error != null && state.publicaciones.isEmpty) {
      return _ErrorState(onRetry: onRefresh);
    }

    if (state.publicaciones.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No hay avisos para tus intereses aún.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.publicaciones.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final p = state.publicaciones[i];
          return PublicacionCard(
            publicacion: p,
            onTap: () => context.push('/publicacion/${p.id}'),
          );
        },
      ),
    );
  }
}

class _SinInteresesState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.interests_rounded,
                size: 72, color: cs.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 20),
            Text(
              'Personaliza tu feed',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Selecciona tus intereses para ver aquí solo los avisos que te importan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.tune_rounded),
              label: const Text('Elegir intereses'),
              onPressed: () => context.push('/intereses'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Sin conexión'),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      );
}

// ─── Tab "Todos" ──────────────────────────────────────────────────────────────

class _TodosTab extends ConsumerWidget {
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;

  const _TodosTab({
    required this.scrollController,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedProvider);

    return Column(
      children: [
        _FilterBar(
          onFilterSelected: () {
            if (scrollController.hasClients) scrollController.jumpTo(0);
          },
        ),
        Expanded(
          child: feedState.isLoading && feedState.publicaciones.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : feedState.publicaciones.isEmpty
                  ? _EmptyTodos(
                      hasError: feedState.error != null,
                      onRetry: onRefresh,
                    )
                  : RefreshIndicator(
                      onRefresh: onRefresh,
                      child: _FeedList(
                        scrollController: scrollController,
                        feedState: feedState,
                      ),
                    ),
        ),
      ],
    );
  }
}

// ─── Lista paginada ───────────────────────────────────────────────────────────

class _FeedList extends ConsumerWidget {
  final ScrollController scrollController;
  final FeedState feedState;

  const _FeedList({
    required this.scrollController,
    required this.feedState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showFooter = !feedState.filtraPorIntereses;
    final itemCount =
        feedState.publicaciones.length + (showFooter ? 1 : 0);

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: itemCount,
      separatorBuilder: (_, i) {
        if (i == feedState.publicaciones.length - 1) {
          return const SizedBox();
        }
        return const SizedBox(height: 12);
      },
      itemBuilder: (context, i) {
        if (i == feedState.publicaciones.length) {
          return _PaginationFooter(
            isLoading: feedState.isLoadingMore,
            hayMas: feedState.hayMas,
            total: feedState.total,
            cargados: feedState.publicaciones.length,
          );
        }
        final p = feedState.publicaciones[i];
        return PublicacionCard(
          publicacion: p,
          onTap: () => context.push('/publicacion/${p.id}'),
        );
      },
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  final bool isLoading;
  final bool hayMas;
  final int total;
  final int cargados;

  const _PaginationFooter({
    required this.isLoading,
    required this.hayMas,
    required this.total,
    required this.cargados,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : hayMas
                ? const SizedBox.shrink()
                : Text(
                    'Has visto todos los avisos ($cargados de $total)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
      ),
    );
  }
}

// ─── Barra de filtros ─────────────────────────────────────────────────────────

class _FilterBar extends ConsumerWidget {
  final VoidCallback onFilterSelected;

  const _FilterBar({required this.onFilterSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ref.watch(feedProvider).params;

    void applyFilter(String? tipo) {
      ref.read(feedProvider.notifier).cargar(
            params: FeedParams(tipo: tipo),
          );
      onFilterSelected();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _FilterChip(
            label: 'Todos',
            selected: params.tipo == null,
            onTap: () => applyFilter(null),
          ),
          const SizedBox(width: 8),
          ...TipoPublicacion.values.map(
            (t) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: _cap(t.value),
                selected: params.tipo == t.value,
                onTap: () => applyFilter(t.value),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? cs.onPrimary : cs.onSurfaceVariant,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ─── Estado vacío tab Todos ───────────────────────────────────────────────────

class _EmptyTodos extends StatelessWidget {
  final bool hasError;
  final Future<void> Function() onRetry;

  const _EmptyTodos({required this.hasError, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasError ? Icons.wifi_off_rounded : Icons.inbox_rounded,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            hasError
                ? 'Sin conexión. Verifica tu red.'
                : 'No hay avisos disponibles.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          if (hasError) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ],
      ),
    );
  }
}
