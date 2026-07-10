part of '../mobile_backend_controller.dart';

extension _MobileBackendOrderController on MobileBackendController {
  Future<Result<CartPreviewModel>> _previewCart(
    CartPreviewRequest request,
  ) {
    return _repository.previewCart(request);
  }

  Future<Result<List<PaymentMethodModel>>> _refreshPaymentMethods({
    required String language,
    String? branchId,
  }) async {
    final result = await _repository.getPaymentMethods(
      language: language,
      branchId: branchId,
    );

    switch (result) {
      case Success(:final data):
        _paymentMethods = data;
        _failure = null;
        notifyListeners();
      case Error(:final failure):
        this._applyFailure(failure);
    }

    return result;
  }

  Future<Result<CustomerOrderModel>> _createOrder(
    CreateOrderRequest request,
  ) async {
    final result = await _repository.createOrder(request);
    switch (result) {
      case Success(:final data):
        _orders = <CustomerOrderModel>[
          data,
          for (final order in _orders)
            if (order.id != data.id) order,
        ];
        _failure = null;
        if (_status == MobileBackendStatus.initial) {
          _status = MobileBackendStatus.loaded;
        }
        notifyListeners();
      case Error(:final failure):
        this._applyFailure(failure, notify: failure is AuthFailure);
    }
    return result;
  }

  Future<Result<CustomerOrderModel>> _retryOrderPayment({
    required String id,
  }) async {
    final result = await _repository.retryOrderPayment(id: id);
    switch (result) {
      case Success(:final data):
        _orders = <CustomerOrderModel>[
          for (final order in _orders)
            if (order.id == data.id) data else order,
        ];
        _failure = null;
        notifyListeners();
      case Error(:final failure):
        this._applyFailure(failure);
    }
    return result;
  }
}
