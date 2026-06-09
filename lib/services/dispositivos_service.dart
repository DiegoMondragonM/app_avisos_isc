import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class DispositivosService {
  DispositivosService._();
  static final DispositivosService instance = DispositivosService._();

  final _client = ApiClient.instance;

  Future<void> registrarToken(String fcmToken, {String plataforma = 'android'}) async {
    await _client.post(
      ApiConstants.dispositivosToken,
      data: {'token': fcmToken, 'plataforma': plataforma},
      withAuth: true,
    );
  }

  Future<void> desactivarToken(String fcmToken) async {
    await _client.delete(
      ApiConstants.dispositivosToken,
      data: {'token': fcmToken},
      withAuth: true,
    );
  }
}
