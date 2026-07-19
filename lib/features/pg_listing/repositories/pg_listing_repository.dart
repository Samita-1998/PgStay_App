import 'package:dio/dio.dart';
import 'package:pgstay/core/api/api_client.dart';
import 'package:pgstay/features/pg_listing/models/post_model.dart';

class PgListingRepository {
  final ApiClient _apiClient;

  PgListingRepository(this._apiClient);

  Future<List<PgPost>> fetchRecommendations({
    String? city,
    String? pgType,
    String? occupancyType,
    double? minPrice,
    double? maxPrice,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (city != null && city.trim().isNotEmpty) {
        queryParams['city'] = city.trim();
      }
      if (pgType != null && pgType != 'All') {
        queryParams['pgType'] = pgType;
      }
      if (occupancyType != null && occupancyType != 'All') {
        queryParams['occupancyType'] = occupancyType.toLowerCase();
      }
      if (minPrice != null && minPrice > 0) {
        queryParams['minPrice'] = minPrice;
      }
      if (maxPrice != null && maxPrice > 0) {
        queryParams['maxPrice'] = maxPrice;
      }

      final response = await _apiClient.dio.get(
        '/post/search',
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final List<dynamic> postsJson = response.data['data']['posts'] ?? [];
        return postsJson.map((json) => PgPost.fromJson(json)).toList();
      } else {
        final List<dynamic> postsJson = response.data['data']?['posts'] ?? [];
        if (postsJson.isNotEmpty) {
          return postsJson.map((json) => PgPost.fromJson(json)).toList();
        }
        throw Exception(response.data['message'] ?? 'Failed to fetch recommendations');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred while fetching stays');
    }
  }

  Future<List<PgPost>> searchPosts({
    String? title,
    String? city,
    String? pgType,
    String? occupancyType,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    List<String>? facilities,
    bool onlyWithVacancy = false,
    int page = 1,
    int limit = 12,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'onlyWithVacancy': onlyWithVacancy,
      };
      if (title != null && title.trim().isNotEmpty) {
        queryParams['title'] = title.trim();
      }
      if (city != null && city.trim().isNotEmpty) {
        queryParams['city'] = city.trim();
      }
      if (pgType != null && pgType != 'Any Type') {
        queryParams['pgType'] = pgType;
      }
      if (occupancyType != null && occupancyType != 'Sharing') {
        queryParams['occupancyType'] = occupancyType.toLowerCase();
      }
      if (minPrice != null && minPrice > 0) {
        queryParams['minPrice'] = minPrice.toInt();
      }
      if (maxPrice != null && maxPrice > 0) {
        queryParams['maxPrice'] = maxPrice.toInt();
      }
      if (minRating != null && minRating > 0) {
        queryParams['minRating'] = minRating;
      }
      if (facilities != null && facilities.isNotEmpty) {
        queryParams['facilities'] = facilities.join(',');
      }

      final response = await _apiClient.dio.get(
        '/post/search',
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final List<dynamic> postsJson = response.data['data']['posts'] ?? [];
        return postsJson.map((json) => PgPost.fromJson(json)).toList();
      } else {
        final List<dynamic> postsJson = response.data['data']?['posts'] ?? [];
        if (postsJson.isNotEmpty) {
          return postsJson.map((json) => PgPost.fromJson(json)).toList();
        }
        throw Exception(response.data['message'] ?? 'Failed to search posts');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred while searching stays');
    }
  }

  Future<PgModel> fetchPgById(String pgId) async {
    try {
      final response = await _apiClient.dio.get('/pg/$pgId');
      if (response.data['success'] == true) {
        final pgJson = response.data['data']['pg'] as Map<String, dynamic>;
        return PgModel.fromJson(pgJson);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch PG details');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error while fetching PG details');
    }
  }

  Future<List<PgPost>> fetchStaffPosts() async {
    try {
      final response = await _apiClient.dio.get('/post');

      if (response.data['success'] == true) {
        final List<dynamic> postsJson = response.data['data']['posts'] ?? [];
        return postsJson.map((json) => PgPost.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch staff posts');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred while fetching stays');
    }
  }

  Future<PgPost> fetchPostDetails(String postId) async {
    try {
      final response = await _apiClient.dio.get('/post/$postId');

      if (response.data['success'] == true) {
        final postJson = response.data['data']['post'];
        return PgPost.fromJson(postJson);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch details');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred while fetching details');
    }
  }

  Future<void> submitEnquiry(String postId) async {
    try {
      final response = await _apiClient.dio.post(
        '/enquiry',
        data: {'postId': postId},
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to submit enquiry');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred while submitting enquiry');
    }
  }

  Future<List<PgModel>> fetchOwnerPGs({int page = 1, int limit = 10}) async {
    try {
      final response = await _apiClient.dio.get('/pg', queryParameters: {
        'page': page,
        'limit': limit,
      });

      if (response.data['success'] == true) {
        final List<dynamic> pgsJson = response.data['data']['pgs'] ?? [];
        return pgsJson.map((json) => PgModel.fromJson(json)).toList();
      } else {
        final List<dynamic> pgsJson = response.data['data']?['pgs'] ?? [];
        if (pgsJson.isNotEmpty) {
          return pgsJson.map((json) => PgModel.fromJson(json)).toList();
        }
        throw Exception(response.data['message'] ?? 'Failed to fetch PGs');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred while fetching PGs');
    }
  }

  Future<List<PgModel>> fetchDiscoverPGs({
    String? city,
    String? pgType,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (city != null && city.trim().isNotEmpty) {
        queryParams['city'] = city.trim();
      }
      if (pgType != null && pgType != 'All') {
        queryParams['pgType'] = pgType;
      }

      final response = await _apiClient.dio.get(
        '/pg/discover',
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final List<dynamic> pgsJson = response.data['data']['pgs'] ?? [];
        return pgsJson.map((json) => PgModel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to discover PGs');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred while fetching discovered PGs');
    }
  }

  Future<void> addPG(Map<String, dynamic> pgData) async {
    try {
      final response = await _apiClient.dio.post(
        '/pg',
        data: pgData,
      );
      
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return; // Success
      }
      
      if (response.data is Map && response.data['success'] == false) {
        throw Exception(response.data['message'] ?? 'Failed to add PG');
      }
    } on DioException catch (e) {
      final message = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(message ?? 'Network error occurred while adding PG');
    }
  }

  Future<void> updatePG(String pgId, Map<String, dynamic> pgData) async {
    try {
      final response = await _apiClient.dio.patch(
        '/pg/$pgId',
        data: pgData,
      );
      
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return; // Success
      }
      
      if (response.data is Map && response.data['success'] == false) {
        throw Exception(response.data['message'] ?? 'Failed to update PG');
      }
    } on DioException catch (e) {
      final message = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(message ?? 'Network error occurred while updating PG');
    }
  }

  Future<List<Map<String, String>>> fetchManagers() async {
    try {
      final response = await _apiClient.dio.get('/staff/managers');

      if (response.data['data'] != null) {
        final List<dynamic> managers = response.data['data']['managers'] ?? [];
        return managers.map<Map<String, String>>((u) {
          return {
            'id': u['_id']?.toString() ?? '',
            'name': u['name']?.toString() ?? 'Manager',
          };
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> fetchRooms(String pgId) async {
    try {
      final response = await _apiClient.dio.get('/room/pg/$pgId');
      if (response.data['success'] == true) {
        return response.data['data'] ?? [];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch rooms');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred while fetching rooms');
    }
  }

  Future<void> addRoom(Map<String, dynamic> roomData) async {
    try {
      final response = await _apiClient.dio.post(
        '/room',
        data: roomData,
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to add room');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred while adding room');
    }
  }

  Future<void> updateRoom(String roomId, Map<String, dynamic> roomData) async {
    try {
      final response = await _apiClient.dio.patch(
        '/room/$roomId',
        data: roomData,
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to update room');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred while updating room');
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      final response = await _apiClient.dio.delete('/room/$roomId');
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return;
      }
      if (response.data is Map && response.data['success'] == false) {
        throw Exception(response.data['message'] ?? 'Failed to delete room');
      }
    } on DioException catch (e) {
      final message = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(message ?? 'Network error occurred while deleting room');
    }
  }

  Future<List<Map<String, dynamic>>> fetchEligibleTenants(String pgId) async {
    try {
      final response = await _apiClient.dio.get('/room/eligible-tenants/$pgId');
      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map) {
          final list = data['tenants'] ?? data['users'] ?? data['candidates'] ?? data['data'] ?? [];
          return List<Map<String, dynamic>>.from(list);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> assignBedToTenant(String bedId, String userId) async {
    try {
      final response = await _apiClient.dio.post(
        '/room/assign/$bedId',
        data: {'userId': userId},
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to assign tenant to bed');
      }
    } on DioException catch (e) {
      final message = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(message ?? 'Network error occurred while assigning tenant');
    }
  }

  Future<void> unassignBedFromTenant(String bedId) async {
    try {
      final response = await _apiClient.dio.post(
        '/room/unassign/$bedId',
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to remove tenant from bed');
      }
    } on DioException catch (e) {
      final message = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(message ?? 'Network error occurred while removing tenant');
    }
  }

  Future<List<Map<String, String>>> fetchFacilities() async {
    try {
      final response = await _apiClient.dio.get('/pg/facilities');

      if (response.data['data'] != null) {
        final List<dynamic> facilities = response.data['data']['facilities'] ?? [];
        return facilities.map<Map<String, String>>((f) {
          return {
            'id': f['_id']?.toString() ?? f['id']?.toString() ?? '',
            'name': f['name']?.toString() ?? '',
          };
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> createPost(Map<String, dynamic> postData) async {
    try {
      final response = await _apiClient.dio.post('/post', data: postData);
      if (response.data['success'] != true && response.data['data'] == null) {
        throw Exception(response.data['message'] ?? 'Failed to create post');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred while creating post');
    }
  }

  Future<void> updatePost(String postId, Map<String, dynamic> postData) async {
    try {
      final response = await _apiClient.dio.patch('/post/$postId', data: postData);
      if (response.data['success'] != true && response.data['data'] == null) {
        throw Exception(response.data['message'] ?? 'Failed to update post');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred while updating post');
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      final response = await _apiClient.dio.delete('/post/$postId');
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return;
      }
      if (response.data is Map && response.data['success'] == false) {
        throw Exception(response.data['message'] ?? 'Failed to delete post');
      }
    } on DioException catch (e) {
      final message = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(message ?? 'Network error occurred while deleting post');
    }
  }

  Future<Map<String, String>> getUploadUrl(String fileName, String fileType) async {
    try {
      final response = await _apiClient.dio.get('/post/upload-url', queryParameters: {
        'fileName': fileName,
        'fileType': fileType,
      });
      if (response.data['success'] == true) {
        final data = response.data['data'];
        return {
          'uploadUrl': data['uploadUrl'],
          'key': data['key'],
        };
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get upload URL');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred while getting upload URL');
    }
  }

  Future<Map<String, String>> getPaymentQrUploadUrl(String fileName, String fileType) async {
    try {
      final response = await _apiClient.dio.get('/pg/payment-qr-upload-url', queryParameters: {
        'fileName': fileName,
        'fileType': fileType,
      });
      if (response.data['success'] == true) {
        final data = response.data['data'];
        return {
          'uploadUrl': data['uploadUrl'],
          'key': data['key'],
        };
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get payment QR upload URL');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error occurred while getting payment QR upload URL');
    }
  }

  Future<void> uploadFileToS3(String uploadUrl, List<int> bytes, String fileType) async {
    try {
      final dio = Dio();
      final response = await dio.put(
        uploadUrl,
        data: bytes,
        options: Options(
          headers: {
            'Content-Type': fileType,
            'Content-Length': bytes.length.toString(),
          },
        ),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to upload file to S3');
      }
    } catch (e) {
      throw Exception('Network error occurred while uploading file: $e');
    }
  }

  Future<void> deleteFile(String fileUrl) async {
    try {
      final uri = Uri.parse(fileUrl);
      final key = uri.path.substring(1); // Removes the leading '/' to get 'public/...'
      
      String endpoint = '/pg/file';
      if (key.startsWith('public/posts/')) {
        endpoint = '/post/file';
      } else if (key.startsWith('public/users/')) {
        endpoint = '/user/file'; // just in case
      }
      
      final response = await _apiClient.dio.delete(
        endpoint,
        data: {'key': key},
      );
      
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        // Success
        return;
      }
      
      if (response.data is Map && response.data['success'] == false) {
        throw Exception(response.data['message'] ?? 'Failed to delete file');
      }
    } on DioException catch (e) {
      final message = e.response?.data is Map ? e.response?.data['message'] : null;
      throw Exception(message ?? 'Network error occurred while deleting file');
    }
  }
}
