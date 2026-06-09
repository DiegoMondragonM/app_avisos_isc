import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/categorias/publicacion_categorizador.dart';
import '../../providers/auth_provider.dart';
import '../../providers/categorias_provider.dart';

class InteresesScreen extends ConsumerStatefulWidget {
  final bool isOnboarding;
  const InteresesScreen({super.key, required this.isOnboarding});

  @override
  ConsumerState<InteresesScreen> createState() => _InteresesScreenState();
}

class _InteresesScreenState extends ConsumerState<InteresesScreen> {
  // Selección en memoria (antes de guardar)
  late List<String> _seleccionadas;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Cargar desde storage y pre-poblar la selección
    _seleccionadas = [];
    Future.microtask(() async {
      await ref.read(categoriasProvider.notifier).cargar();
      if (mounted) {
        setState(() {
          _seleccionadas =
              List.from(ref.read(categoriasProvider).seleccionadas);
        });
      }
    });
  }

  void _toggle(String categoria) {
    setState(() {
      if (_seleccionadas.contains(categoria)) {
        _seleccionadas.remove(categoria);
      } else {
        _seleccionadas.add(categoria);
      }
    });
  }

  Future<void> _guardar() async {
    setState(() => _saving = true);
    try {
      await ref.read(categoriasProvider.notifier).guardar(_seleccionadas);
      if (mounted) {
        if (widget.isOnboarding) {
          ref.read(authProvider.notifier).completarOnboarding();
          context.go('/home');
        } else {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Intereses actualizados')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final categorias = todasLasCategorias;

    return Scaffold(
      appBar: widget.isOnboarding
          ? null
          : AppBar(title: const Text('Mis intereses')),
      body: SafeArea(
        child: Column(
          children: [
            // ── Encabezado ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(
                children: [
                  if (widget.isOnboarding) ...[
                    Icon(Icons.interests_rounded,
                        size: 52, color: cs.primary),
                    const SizedBox(height: 12),
                    Text(
                      '¿Qué temas te interesan?',
                      textAlign: TextAlign.center,
                      style: tt.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Elige las áreas que más te importan. Solo verás avisos relacionados con ellas.',
                      textAlign: TextAlign.center,
                      style: tt.bodyMedium
                          ?.copyWith(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),
                  ],
                  // Contador de selección + "Seleccionar todo"
                  Row(
                    children: [
                      Text(
                        '${_seleccionadas.length} de ${categorias.length} seleccionadas',
                        style:
                            tt.labelMedium?.copyWith(color: cs.outline),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() {
                          if (_seleccionadas.length == categorias.length) {
                            _seleccionadas = [];
                          } else {
                            _seleccionadas = List.from(categorias);
                          }
                        }),
                        child: Text(
                          _seleccionadas.length == categorias.length
                              ? 'Quitar todo'
                              : 'Seleccionar todo',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Grid de categorías ────────────────────────────────────────
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: categorias.length,
                itemBuilder: (context, i) {
                  final nombre = categorias[i];
                  final seleccionada = _seleccionadas.contains(nombre);
                  return _CategoriaCard(
                    nombre: nombre,
                    seleccionada: seleccionada,
                    onTap: () => _toggle(nombre),
                  );
                },
              ),
            ),

            // ── Botones ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: _saving ? null : _guardar,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.isOnboarding
                            ? 'Continuar'
                            : 'Guardar intereses'),
                  ),
                  if (widget.isOnboarding)
                    TextButton(
                      onPressed: () {
                        ref
                            .read(authProvider.notifier)
                            .completarOnboarding();
                        context.go('/home');
                      },
                      child: const Text('Omitir por ahora'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tarjeta de categoría ─────────────────────────────────────────────────────

class _CategoriaCard extends StatelessWidget {
  final String nombre;
  final bool seleccionada;
  final VoidCallback onTap;

  const _CategoriaCard({
    required this.nombre,
    required this.seleccionada,
    required this.onTap,
  });

  static const _colores = <String, Color>{
    'Programación': Color(0xFF1565C0),
    'IA y Datos': Color(0xFF6A1B9A),
    'Web y Móvil': Color(0xFF00838F),
    'Redes y Ciberseguridad': Color(0xFFBF360C),
    'Bases de Datos': Color(0xFF4527A0),
    'Cloud y DevOps': Color(0xFF0277BD),
    'IoT y Robótica': Color(0xFF558B2F),
    'Idiomas y Cultura': Color(0xFF1B5E20),
    'Innovación y Emprendimiento': Color(0xFFE65100),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colores[nombre] ?? Colors.grey.shade700;
    final icono = categoriasIconos[nombre] ?? '📋';

    // Mostrar 3 keywords de muestra
    final keywords = (categoriasKeywords[nombre] ?? []).take(3).join(', ');

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: seleccionada ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionada
                ? color
                : color.withValues(alpha: 0.3),
            width: seleccionada ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icono, style: const TextStyle(fontSize: 22)),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: seleccionada
                      ? Icon(Icons.check_circle_rounded,
                          key: const ValueKey(true),
                          color: Colors.white,
                          size: 20)
                      : Icon(Icons.circle_outlined,
                          key: const ValueKey(false),
                          color: color.withValues(alpha: 0.5),
                          size: 20),
                ),
              ],
            ),
            const Spacer(),
            Text(
              nombre,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: seleccionada ? Colors.white : color,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              keywords,
              style: TextStyle(
                fontSize: 10,
                color: seleccionada
                    ? Colors.white.withValues(alpha: 0.75)
                    : Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
