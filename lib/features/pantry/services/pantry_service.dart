import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/pantry_models.dart';

/// ──────────────────────────────────────────────
/// Pantry API Service
/// Mirrors: pp-backend modules/pantry/services/pantry.service.ts
/// Endpoints: GET/POST/PATCH/DELETE /me/pantry,
///            POST /me/pantry/upload-url,
///            POST /me/pantry/parse-image,
///            POST /me/pantry/items/bulk
/// ──────────────────────────────────────────────

class PantryService {
  final _dio = ApiClient.instance.dio;

  /// GET /me/pantry
  Future<List<PantryItem>> fetchItems() async {
    final response = await _dio.get('/me/pantry');
    final list = response.data['items'] as List<dynamic>;
    return list
        .map((item) => PantryItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// POST /me/pantry
  Future<PantryItem> addItem(AddPantryItemPayload payload) async {
    final response = await _dio.post('/me/pantry', data: payload.toJson());
    return PantryItem.fromJson(response.data as Map<String, dynamic>);
  }

  /// PATCH /me/pantry/:id
  Future<PantryItem> updateItem(
      String id, UpdatePantryItemPayload payload) async {
    final response =
        await _dio.patch('/me/pantry/$id', data: payload.toJson());
    return PantryItem.fromJson(response.data as Map<String, dynamic>);
  }

  /// DELETE /me/pantry/:id
  Future<void> deleteItem(String id) async {
    await _dio.delete('/me/pantry/$id');
  }

  /// POST /me/pantry/items/bulk
  Future<List<PantryItem>> bulkAddItems(
      List<AddPantryItemPayload> items) async {
    final response = await _dio.post('/me/pantry/items/bulk', data: {
      'items': items.map((i) => i.toJson()).toList(),
    });
    final list = response.data['items'] as List<dynamic>;
    return list
        .map((item) => PantryItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// POST /me/pantry/upload-url
  Future<Map<String, dynamic>> getUploadUrl(
      String filename, String contentType) async {
    final response = await _dio.post('/me/pantry/upload-url', data: {
      'filename': filename,
      'contentType': contentType,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Upload binary image directly to S3 presigned URL
  Future<void> uploadToS3(String presignedUrl, List<int> bytes,
      String contentType) async {
    final plainDio = Dio(); // No interceptors for direct S3 upload
    await plainDio.put(
      presignedUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          'Content-Type': contentType,
          Headers.contentLengthHeader: bytes.length,
        },
      ),
    );
  }

  /// POST /me/pantry/parse-image
  Future<List<ParsedIngredient>> parseImage(String imageKey) async {
    final response = await _dio.post('/me/pantry/parse-image', data: {
      'imageKey': imageKey,
    });
    final list = response.data['items'] as List<dynamic>;
    return list
        .map((item) =>
            ParsedIngredient.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
