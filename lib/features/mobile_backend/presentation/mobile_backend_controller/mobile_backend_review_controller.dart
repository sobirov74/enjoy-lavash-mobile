part of '../mobile_backend_controller.dart';

extension _MobileBackendReviewController on MobileBackendController {
  Future<Result<CustomerOrderModel>> _submitOrderReview({
    required String orderId,
    required int rating,
    String? comment,
    required List<String> photoPaths,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final generation = _sessionGeneration;
    final result = await _repository.submitOrderReview(
      orderId: orderId,
      rating: rating,
      comment: comment,
      photoPaths: photoPaths,
      onSendProgress: onSendProgress,
    );
    if (!_isCurrentSession(generation)) return const Error(AuthFailure());
    switch (result) {
      case Success(:final data):
        _upsertOrder(data);
        _failure = null;
        _notifyListeners();
      case Error(failure: ConflictFailure(errorCode: 'ORDER_ALREADY_REVIEWED')):
        final refreshed = await refreshOrder(id: orderId);
        if (!_isCurrentSession(generation)) return const Error(AuthFailure());
        return refreshed;
      case Error(:final failure):
        _applyFailure(failure, notify: failure is AuthFailure);
    }
    return result;
  }
}
