part of '../mobile_backend_controller.dart';

extension _MobileBackendLoyaltyController on MobileBackendController {
  Future<Result<LoyaltyWalletModel>> _refreshLoyaltyWallet() async {
    if (_client == null) {
      return const Error<LoyaltyWalletModel>(AuthFailure());
    }

    final requestVersion = ++_loyaltyWalletRequestVersion;
    _loyaltyWalletLoading = true;
    _loyaltyWalletFailure = null;
    _notifyListeners();

    late Result<LoyaltyWalletModel> result;
    try {
      result = await _repository.getLoyaltyWallet();
    } catch (error) {
      result = Error<LoyaltyWalletModel>(UnknownFailure(error.toString()));
    }
    if (requestVersion != _loyaltyWalletRequestVersion || _client == null) {
      return result;
    }

    switch (result) {
      case Success(:final data):
        _loyaltyWallet = data;
        _loyaltyWalletFailure = null;
        _failure = null;
      case Error(:final failure):
        _loyaltyWalletFailure = failure;
        _applyFailure(failure, notify: false);
    }
    _loyaltyWalletLoading = false;
    _notifyListeners();
    return result;
  }

  Future<Result<LoyaltyTransactionPageModel>> _refreshLoyaltyTransactions({
    int limit = 50,
  }) async {
    if (_client == null) {
      return const Error<LoyaltyTransactionPageModel>(AuthFailure());
    }
    final requestVersion = ++_loyaltyTransactionsRequestVersion;
    _loyaltyTransactionsLoading = true;
    _loyaltyTransactionsLoadingMore = false;
    _loyaltyTransactionsFailure = null;
    _notifyListeners();

    late Result<LoyaltyTransactionPageModel> result;
    try {
      result = await _repository.getLoyaltyTransactions(limit: limit);
    } catch (error) {
      result = Error<LoyaltyTransactionPageModel>(
        UnknownFailure(error.toString()),
      );
    }
    if (requestVersion != _loyaltyTransactionsRequestVersion ||
        _client == null) {
      return result;
    }
    switch (result) {
      case Success(:final data):
        _loyaltyTransactions = data.items;
        _loyaltyTransactionsNextCursor = data.nextCursor;
        _loyaltyTransactionsFailure = null;
        _failure = null;
      case Error(:final failure):
        _loyaltyTransactionsFailure = failure;
        _applyFailure(failure, notify: false);
    }
    _loyaltyTransactionsLoading = false;
    _notifyListeners();
    return result;
  }

  Future<Result<LoyaltyTransactionPageModel>> _loadMoreLoyaltyTransactions({
    int limit = 50,
  }) async {
    final cursor = _loyaltyTransactionsNextCursor;
    if (_client == null) {
      return const Error<LoyaltyTransactionPageModel>(AuthFailure());
    }
    if (cursor == null || _loyaltyTransactionsLoadingMore) {
      return Success(
        LoyaltyTransactionPageModel(
          items: const <LoyaltyTransactionModel>[],
          nextCursor: cursor,
        ),
      );
    }

    final requestVersion = _loyaltyTransactionsRequestVersion;
    _loyaltyTransactionsLoadingMore = true;
    _loyaltyTransactionsFailure = null;
    _notifyListeners();

    late Result<LoyaltyTransactionPageModel> result;
    try {
      result = await _repository.getLoyaltyTransactions(
        limit: limit,
        cursor: cursor,
      );
    } catch (error) {
      result = Error<LoyaltyTransactionPageModel>(
        UnknownFailure(error.toString()),
      );
    }
    if (requestVersion != _loyaltyTransactionsRequestVersion ||
        _client == null) {
      return result;
    }
    switch (result) {
      case Success(:final data):
        final ids = _loyaltyTransactions.map((item) => item.id).toSet();
        _loyaltyTransactions = <LoyaltyTransactionModel>[
          ..._loyaltyTransactions,
          for (final item in data.items)
            if (ids.add(item.id)) item,
        ];
        _loyaltyTransactionsNextCursor = data.nextCursor;
        _loyaltyTransactionsFailure = null;
      case Error(:final failure):
        _loyaltyTransactionsFailure = failure;
        _applyFailure(failure, notify: false);
    }
    _loyaltyTransactionsLoadingMore = false;
    _notifyListeners();
    return result;
  }
}
