import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/publicacion.dart';

class PublicacionesService {
  PublicacionesService._();
  static final PublicacionesService instance = PublicacionesService._();

  final _client = ApiClient.instance;

  Future<({int total, int page, int limit, int paginas, List<Publicacion> publicaciones})>
      getPublicaciones({
    String? tipo,
    String? fuente,
    String? tag,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _client.get(ApiConstants.publicaciones, queryParameters: {
      if (tipo != null) 'tipo': tipo,
      if (fuente != null) 'fuente': fuente,
      if (tag != null) 'tag': tag,
      'page': page,
      'limit': limit,
    });

    final data = res.data as Map<String, dynamic>;
    final list = (data['publicaciones'] as List<dynamic>)
        .map((p) => Publicacion.fromJson(p as Map<String, dynamic>))
        .toList();

    return (
      total: data['total'] as int,
      page: data['page'] as int,
      limit: data['limit'] as int,
      paginas: data['paginas'] as int,
      publicaciones: list,
    );
  }

  Future<Publicacion> getDetalle(int id) async {
    final res = await _client.get(ApiConstants.publicacionDetalle(id));
    return Publicacion.fromJson(res.data['publicacion'] as Map<String, dynamic>);
  }
}
