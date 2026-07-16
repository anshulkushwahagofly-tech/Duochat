import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central REST client for the DuoChat backend.
/// Base URL should point at your deployed backend, e.g.
/// https://api.duochat.app  (see docs/DEPLOYMENT_GUIDE.md)
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio dio;
  static const String baseUrl = String.fromEnvironment(
    'DUOCHAT_API_BASE_URL',
    defaultValue: 'https://api.duochat.app/api',
  );

  ApiService._internal() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('duochat_jwt');
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
    ));
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('duochat_jwt', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('duochat_jwt');
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('duochat_jwt');
  }

  // ---- Auth ----
  Future<Response> verifyOtp({
    required String idToken,
    required String deviceId,
    required String deviceName,
    required String platform,
    String? fcmToken,
  }) {
    return dio.post('/auth/verify-otp', data: {
      'idToken': idToken,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'platform': platform,
      'fcmToken': fcmToken,
    });
  }

  // ---- Profile ----
  Future<Response> getMe() => dio.get('/users/me');
  Future<Response> updateMe(Map<String, dynamic> data) => dio.put('/users/me', data: data);

  // ---- Chats ----
  Future<Response> getChats() => dio.get('/chats');
  Future<Response> getOrCreateOneToOne(String userId) => dio.post('/chats/one-to-one', data: {'userId': userId});
  Future<Response> createGroup(String groupName, List<String> participantIds) =>
      dio.post('/chats/group', data: {'groupName': groupName, 'participantIds': participantIds});

  // ---- Messages ----
  Future<Response> getMessages(String chatId, {String? before}) =>
      dio.get('/messages/$chatId', queryParameters: {if (before != null) 'before': before});
  Future<Response> sendMessage(Map<String, dynamic> data) => dio.post('/messages', data: data);

  // ---- Status ----
  Future<Response> getStatusFeed() => dio.get('/status/feed');
  Future<Response> postStatus(Map<String, dynamic> data) => dio.post('/status', data: data);

  // ---- Upload ----
  Future<Response> uploadFile(String filePath, String folder) async {
    final formData = FormData.fromMap({
      'folder': folder,
      'file': await MultipartFile.fromFile(filePath),
    });
    return dio.post('/upload', data: formData);
  }
}
