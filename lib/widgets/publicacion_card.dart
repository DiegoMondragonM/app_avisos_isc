import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/publicacion.dart';
import 'publicacion_image.dart';
import 'tag_chip.dart';

class PublicacionCard extends StatelessWidget {
  final Publicacion publicacion;
  final VoidCallback onTap;

  const PublicacionCard({
    super.key,
    required this.publicacion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PublicacionImage(
              url: publicacion.imagenUrl,
              tipo: publicacion.tipo,
              fuente: publicacion.fuente,
              height: 140,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _TipoBadge(tipo: publicacion.tipo),
                      const Spacer(),
                      if (publicacion.fechaInicio != null)
                        Text(
                          DateFormat('d MMM yyyy', 'es')
                              .format(publicacion.fechaInicio!),
                          style: tt.labelSmall
                              ?.copyWith(color: cs.outline),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    publicacion.titulo,
                    style: tt.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (publicacion.descripcion != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      publicacion.descripcion!,
                      style: tt.bodySmall?.copyWith(color: cs.outline),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (publicacion.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: publicacion.tags
                          .take(3)
                          .map((t) => TagChip(tag: t, small: true))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Badge de tipo ────────────────────────────────────────────────────────────

class _TipoBadge extends StatelessWidget {
  final String tipo;
  const _TipoBadge({required this.tipo});

  static const _colores = <String, Color>{
    'curso': Color(0xFF1565C0),
    'taller': Color(0xFF2E7D32),
    'concurso': Color(0xFFE65100),
    'conferencia': Color(0xFF6A1B9A),
    'beca': Color(0xFF00838F),
    'otro': Color(0xFF546E7A),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colores[tipo] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        tipo.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
