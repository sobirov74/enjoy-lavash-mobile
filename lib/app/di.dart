import 'package:get_it/get_it.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/data/repositories/auth.dart';
import 'package:enjoy_lavash_mobile/core/data/repositories/order_repository.dart';
import 'package:enjoy_lavash_mobile/core/data/repositories/organisation_repository.dart';
import 'package:enjoy_lavash_mobile/core/data/repositories/product_repository.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/repositories/mobile_backend_repository_impl.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/repositories/mobile_backend_repository.dart';

final sl = GetIt.instance;

void setupDi() {
  // -- Core
  sl.registerLazySingleton<ApiClient>(ApiClient.new);
  sl.registerLazySingleton<MobilePushNotificationService>(
    () => MobilePushNotificationService(sl<ApiClient>()),
  );

  // -- Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepository(sl<ApiClient>()),
  );
  sl.registerLazySingleton<OrderRepository>(
    () => OrderRepository(sl<ApiClient>()),
  );
  sl.registerLazySingleton<OrderProductRepository>(
    () => OrderProductRepository(sl<ApiClient>()),
  );
  sl.registerLazySingleton<OrganisationRepository>(
    () => OrganisationRepository(sl<ApiClient>()),
  );
  sl.registerLazySingleton<MobileBackendRepository>(
    () => MobileBackendRepositoryImpl(sl<ApiClient>()),
  );
}
