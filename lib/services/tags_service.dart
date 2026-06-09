import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/tag.dart';

class TagsService {
  TagsService._();
  static final TagsService instance = TagsService._();

  final _client = ApiClient.instance;

  Future<List<Tag>> getTags() async {
    final res = await _client.get(ApiConstants.tags);
    final list = res.data['tags'] as List<dynamic>;
    return list.map((t) => Tag.fromJson(t as Map<String, dynamic>)).toList();
  }

  Future<List<Tag>> getMisIntereses() async {
    final res = await _client.get(ApiConstants.misIntereses, withAuth: true);
    final list = res.data['intereses'] as List<dynamic>;
    return list.map((t) => Tag.fromJson(t as Map<String, dynamic>)).toList();
  }

  Future<void> saveMisIntereses(List<int> tagIds) async {
    await _client.put(
      ApiConstants.misIntereses,
      data: {'tag_ids': tagIds},
      withAuth: true,
    );
  }
}
