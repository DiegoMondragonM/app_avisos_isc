import 'package:flutter/material.dart';

/// Muestra la imagen de red de una publicación.
/// Si la URL es nula, vacía o falla la carga → placeholder con gradiente
/// e icono según el tipo. Las publicaciones de fuente MOOC muestran
/// un badge "MOOC TecNM" en la esquina inferior derecha.
class PublicacionImage extends StatelessWidget {
  final String? url;
  final String tipo;
  final String fuente;
  final double height;
  final BorderRadius? borderRadius;

  const PublicacionImage({
    super.key,
    required this.url,
    required this.tipo,
    required this.fuente,
    this.height = 200,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final validUrl = url != null && url!.isNotEmpty;
    final br = borderRadius ?? BorderRadius.zero;

    Widget image;

    if (validUrl) {
      image = Image.network(
        url!,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => PublicacionPlaceholder(
          tipo: tipo,
          fuente: fuente,
          height: height,
        ),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            height: height,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    } else {
      image = PublicacionPlaceholder(tipo: tipo, fuente: fuente, height: height);
    }

    if (br == BorderRadius.zero) return image;
    return ClipRRect(borderRadius: br, child: image);
  }
}

/// Placeholder con gradiente e icono según tipo de publicación.
class PublicacionPlaceholder extends StatelessWidget {
  final String tipo;
  final String fuente;
  final double height;

  const PublicacionPlaceholder({
    super.key,
    required this.tipo,
    required this.fuente,
    required this.height,
  });

  static const _gradients = <String, List<Color>>{
    'curso': [Color(0xFF1565C0), Color(0xFF42A5F5)],
    'taller': [Color(0xFF2E7D32), Color(0xFF66BB6A)],
    'concurso': [Color(0xFFE65100), Color(0xFFFF8A65)],
    'conferencia': [Color(0xFF6A1B9A), Color(0xFFBA68C8)],
    'beca': [Color(0xFF00838F), Color(0xFF4DD0E1)],
    'otro': [Color(0xFF455A64), Color(0xFF90A4AE)],
  };

  static const _icons = <String, IconData>{
    'curso': Icons.school_rounded,
    'taller': Icons.build_rounded,
    'concurso': Icons.emoji_events_rounded,
    'conferencia': Icons.record_voice_over_rounded,
    'beca': Icons.savings_rounded,
    'otro': Icons.announcement_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[tipo] ??
        [const Color(0xFF455A64), const Color(0xFF90A4AE)];
    final icon = _icons[tipo] ?? Icons.article_rounded;
    final isMooc = fuente.toLowerCase() == 'mooc';

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.white.withValues(alpha: 0.25)),
          if (isMooc)
            Positioned(
              bottom: 10,
              right: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'MOOC TecNM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
