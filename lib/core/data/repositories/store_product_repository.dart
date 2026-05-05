import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/api/api_endpoints.dart';
import 'package:enjoy_lavash_mobile/core/data/models/base_paginate.dart';
import 'package:enjoy_lavash_mobile/core/data/models/product.dart';

// ignore_for_file: constant_identifier_names
enum ActiveSection { SELLS, EXORD, SPECIAL, SAP }

class StoreProductRepository {
  final ApiClient apiClient;

  StoreProductRepository(this.apiClient);

  Future<PaginatedResponse<Product>> getProducts({
    int page = 1,
    int size = 20,
    required String storeId,
    required ActiveSection activeSection,
    String? name,
  }) async {
    final response = await apiClient.dio.get(
      ApiEndpoints.products,
      queryParameters: {
        'page': page,
        'size': size,
        'is_accessible': true,
        'active_section': activeSection.name,
        'store_id': storeId,
        'name': ?name,
      },
    );

    return PaginatedResponse<Product>.fromJson(
      response.data,
      (json) => Product.fromJson(json),
    );
  }
}
