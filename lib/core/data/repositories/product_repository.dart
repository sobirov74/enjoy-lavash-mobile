import 'package:dio/dio.dart';
import 'package:enjoy_lavash_mobile/widgets/utils/error_extracter.dart'
    as Extracter;
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/api/api_endpoints.dart';
import 'package:enjoy_lavash_mobile/core/data/models/base_paginate.dart';
import 'package:enjoy_lavash_mobile/core/data/models/order_product.dart';
import 'package:enjoy_lavash_mobile/core/data/models/scan_res.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:vibration/vibration.dart';

class OrderProductRepository {
  final ApiClient apiClient;

  OrderProductRepository(this.apiClient);

  Future<PaginatedResponse<OrderProducts>> getOrderProducts({
    required String id,
  }) async {
    final response = await apiClient.dio.get(
      '${ApiEndpoints.orders}$id/products',
      data: {"disable_pagination": true},
    );

    return PaginatedResponse<OrderProducts>.fromJson(
      response.data,
      (json) => OrderProducts.fromJson(json),
    );
  }

  Future<void> scannerProd({required String id}) async {
    try {
      final response = await apiClient.dio.put('${ApiEndpoints.scan}/$id/scan');

      final ScanResponse data = ScanResponse.fromJson(response.data);

      debugPrint('scanned prod ${data.toString()}');

      if (await Vibration.hasVibrator()) {
        Vibration.vibrate();
      }

      Fluttertoast.showToast(
        msg: "${data.orderProduct.product.name} x${data.expectedQuantity}",
        backgroundColor: BaseColors.success,
        textColor: BaseColors.white,
      );

      // return ScanResponse.fromJson(response.data);
    } on DioException catch (e) {
      final error = Extracter.extractErrorMessage(e);
      Fluttertoast.showToast(
        msg: error,
        backgroundColor: BaseColors.danger,
        textColor: BaseColors.white,
      );
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 50, amplitude: 128);
      }
    }
  }

  Future<void> updateProds({
    required String id,
    required String productId,
    required String deliveredUnits,
  }) async {
    debugPrint('productId $productId deliveredUnits $deliveredUnits');
    try {
      await apiClient.dio.patch(
        '${ApiEndpoints.orders}$id',
        data: {
          "update_products": [
            {'id': productId, "delivered_units": deliveredUnits},
          ],
        },
      );

      Fluttertoast.showToast(
        msg: 'Успешно изменен',
        backgroundColor: BaseColors.success,
        textColor: BaseColors.white,
      );

      // final ScanResponse data = ScanResponse.fromJson(response.data);
      // return
      // return ScanResponse.fromJson(response.data);
    } on DioException catch (e) {
      final error = Extracter.extractErrorMessage(e);
      Fluttertoast.showToast(
        msg: error,
        backgroundColor: BaseColors.danger,
        textColor: BaseColors.white,
      );
    }
  }
}
