import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/api/api_endpoints.dart';
import 'package:enjoy_lavash_mobile/core/data/models/user.dart';

class AuthRepository {
  final ApiClient apiClient;

  AuthRepository(this.apiClient);

  Future<User> getMe() async {
    final response = await apiClient.dio.get(ApiEndpoints.me);
    return User.fromJson(response.data);
  }
}
