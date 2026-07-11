part of '../mobile_backend_controller.dart';

extension _MobileBackendOrderController on MobileBackendController {
  Future<Result<CartPreviewModel>> _previewCart(CartPreviewRequest request) {
    return _repository.previewCart(request);
  }

  Future<Result<List<PaymentMethodModel>>> _refreshPaymentMethods({
    required String language,
    String? branchId,
  }) async {
    final normalizedBranchId = _normalizedBranchId(branchId);
    final requestVersion = ++_paymentMethodsRequestVersion;
    _paymentMethods = const <PaymentMethodModel>[];
    _paymentMethodsBranchId = normalizedBranchId;
    _paymentMethodsFailure = null;
    _paymentMethodsLoading = true;
    _notifyListeners();

    final result = await _repository.getPaymentMethods(
      language: language,
      branchId: normalizedBranchId,
    );

    if (requestVersion != _paymentMethodsRequestVersion) return result;

    switch (result) {
      case Success(:final data):
        _paymentMethods = data;
        _paymentMethodsFailure = null;
        _failure = null;
      case Error(:final failure):
        _paymentMethods = const <PaymentMethodModel>[];
        _paymentMethodsFailure = failure;
        _applyFailure(failure, notify: false);
    }

    _paymentMethodsLoading = false;
    _notifyListeners();
    return result;
  }

  String? _normalizedBranchId(String? branchId) {
    final value = branchId?.trim();
    return value == null || value.isEmpty ? null : value;
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
        _notifyListeners();
      case Error(:final failure):
        _applyFailure(failure, notify: failure is AuthFailure);
    }
    return result;
  }

  Future<Result<CustomerOrderModel>> _refreshOrder({required String id}) async {
    final result = await _repository.getOrder(id: id);
    switch (result) {
      case Success(:final data):
        _upsertOrder(data);
        _failure = null;
        _notifyListeners();
      case Error(:final failure):
        _applyFailure(failure);
    }
    return result;
  }

  Future<Result<CustomerOrderModel>> _retryOrderPayment({
    required String id,
  }) async {
    final result = await _repository.retryOrderPayment(id: id);
    switch (result) {
      case Success(:final data):
        _upsertOrder(data);
        _failure = null;
        _notifyListeners();
      case Error(:final failure):
        _applyFailure(failure);
    }
    return result;
  }

  void _upsertOrder(CustomerOrderModel updatedOrder) {
    final hasOrder = _orders.any((order) => order.id == updatedOrder.id);
    if (!hasOrder) {
      _orders = <CustomerOrderModel>[updatedOrder, ..._orders];
      return;
    }
    _orders = <CustomerOrderModel>[
      for (final order in _orders)
        if (order.id == updatedOrder.id) updatedOrder else order,
    ];
  }
}
