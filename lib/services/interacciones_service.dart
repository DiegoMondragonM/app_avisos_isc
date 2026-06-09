import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

enum TipoEvento {
  viewDetail('view_detail'),
  openLink('open_link'),
  favorite('favorite'),
  tapNotification('tap_notification');

  const TipoEvento(this.value);
  final String value;
}

class InteraccionesService {
  InteraccionesService._();
  static final InteraccionesService instance = InteraccionesService._();

  final _client = ApiClient.instance;

  Future<void> registrar(int publicacionId, TipoEvento tipo) async {
    try {
      await _client.post(
        ApiConstants.interacciones,
        data: {
          'publicacion_id': publicacionId,
          'tipo_evento': tipo.value,
        },
        withAuth: true,
      );
    } catch (_) {
      // Las interacciones son métricas: si fallan no afectan la experiencia.
    }
  }
}
