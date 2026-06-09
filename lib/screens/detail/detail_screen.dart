import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/publicaciones_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/interacciones_service.dart';
import '../../models/publicacion.dart';
import '../../widgets/publicacion_image.dart';
import '../../widgets/tag_chip.dart';

class DetailScreen extends ConsumerStatefulWidget {
  final int id;
  const DetailScreen({super.key, required this.id});

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  @override
  void initState() {
    super.initState();
    // Registrar vista de detalle
    Future.microtask(() {
      final authState = ref.read(authProvider);
      if (authState is AuthAuthenticated) {
        InteraccionesService.instance
            .registrar(widget.id, TipoEvento.viewDetail);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final detalleAsync = ref.watch(detallePublicacionProvider(widget.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: detalleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text(e.toString()),
              TextButton(
                onPressed: () =>
                    ref.refresh(detallePublicacionProvider(widget.id)),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (pub) {
          if (!pub.isPublicada) {
            return const Center(
              child: Text('Este aviso ya no está disponible.'),
            );
          }
          return _DetalleBody(publicacion: pub);
        },
      ),
    );
  }
}

class _DetalleBody extends ConsumerWidget {
  final Publicacion publicacion;
  const _DetalleBody({required this.publicacion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fmt = DateFormat('EEEE d \'de\' MMMM yyyy, HH:mm', 'es');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PublicacionImage(
            url: publicacion.imagenUrl,
            tipo: publicacion.tipo,
            fuente: publicacion.fuente,
            height: 200,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 16),
          // Tipo badge
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  publicacion.tipo.toUpperCase(),
                  style: tt.labelSmall?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            publicacion.titulo,
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (publicacion.descripcion != null) ...[
            const SizedBox(height: 12),
            Text(publicacion.descripcion!, style: tt.bodyMedium),
          ],
          const SizedBox(height: 20),
          const Divider(),
          // Fechas
          _InfoRow(
            icon: Icons.event,
            label: 'Inicio del evento',
            value: publicacion.fechaInicio != null
                ? fmt.format(publicacion.fechaInicio!)
                : 'No especificado',
          ),
          if (publicacion.fechaFin != null)
            _InfoRow(
              icon: Icons.event_available,
              label: 'Fin del evento',
              value: fmt.format(publicacion.fechaFin!),
            ),
          if (publicacion.fechaInscripcionFin != null)
            _InfoRow(
              icon: Icons.how_to_reg,
              label: 'Inscripción hasta',
              value: fmt.format(publicacion.fechaInscripcionFin!),
            ),
          // Tags
          if (publicacion.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Temas', style: tt.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: publicacion.tags
                  .map((t) => TagChip(tag: t))
                  .toList(),
            ),
          ],
          // Link externo (usa effectiveLink → si es MOOC sin link, apunta a mooc.tecnm.mx)
          if (publicacion.effectiveLink != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: Text(
                publicacion.fuente.toLowerCase() == 'mooc' &&
                        publicacion.link == null
                    ? 'Ver en MOOC TecNM'
                    : 'Más información / Inscribirme',
              ),
              onPressed: () async {
                final authState = ref.read(authProvider);
                if (authState is AuthAuthenticated) {
                  InteraccionesService.instance
                      .registrar(publicacion.id, TipoEvento.openLink);
                }
                final uri = Uri.tryParse(publicacion.effectiveLink!);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri,
                      mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
                Text(value,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
