import 'package:intl/intl.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/api/api_endpoints.dart';
import 'package:enjoy_lavash_mobile/core/data/models/base_paginate.dart';
import 'package:enjoy_lavash_mobile/core/data/models/order.dart';
import 'package:enjoy_lavash_mobile/core/data/models/order_details.dart';

class OrderRepository {
  final ApiClient apiClient;

  OrderRepository(this.apiClient);

  Future<PaginatedResponse<OrderItem>> getOrders({
    required int page,
    List<String>? status,
    String? type,
    DateTime? deliveryDatetime,
  }) async {
    final String? dateTime = deliveryDatetime != null
        ? DateFormat('yyyy-MM-dd').format(deliveryDatetime)
        : null;
    final response = await apiClient.dio.get(
      ApiEndpoints.orders,
      queryParameters: {
        'page': page,
        'status': status,
        'type': ?type,
        "delivery_datetime": ?dateTime,
        "include_groups": true,
      },
    );

    return PaginatedResponse<OrderItem>.fromJson(
      response.data,
      (json) => OrderItem.fromJson(json),
    );
  }

  Future<OrderDetails> getOrder({required String id}) async {
    final response = await apiClient.dio.get(ApiEndpoints.orders + id);

    return OrderDetails.fromJson(response.data as Map<String, dynamic>);
  }
}
