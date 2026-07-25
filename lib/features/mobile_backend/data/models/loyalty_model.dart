import 'json_helpers.dart';

class LoyaltyWalletModel {
  const LoyaltyWalletModel({
    required this.availableBalance,
    required this.reservedBalance,
    required this.debtBalance,
    required this.spendableBalance,
    required this.expiringWithinSevenDays,
    required this.validityDays,
    required this.reminderDays,
    required this.programEnabled,
    required this.redemptionEnabled,
    required this.spendOnDelivery,
    required this.spendOnServiceFee,
    this.nextExpiryAt,
  });

  final int availableBalance;
  final int reservedBalance;
  final int debtBalance;
  final int spendableBalance;
  final DateTime? nextExpiryAt;
  final int expiringWithinSevenDays;
  final int validityDays;
  final int reminderDays;
  final bool programEnabled;
  final bool redemptionEnabled;
  final bool spendOnDelivery;
  final bool spendOnServiceFee;

  bool get canRedeem =>
      programEnabled &&
      redemptionEnabled &&
      debtBalance == 0 &&
      spendableBalance > 0;

  factory LoyaltyWalletModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyWalletModel(
      availableBalance: readInt(json, const [
        'availableBalance',
        'available_balance',
      ]),
      reservedBalance: readInt(json, const [
        'reservedBalance',
        'reserved_balance',
      ]),
      debtBalance: readInt(json, const ['debtBalance', 'debt_balance']),
      spendableBalance: readInt(json, const [
        'spendableBalance',
        'spendable_balance',
      ]),
      nextExpiryAt: readDateTime(json, const [
        'nextExpiryAt',
        'next_expiry_at',
      ]),
      expiringWithinSevenDays: readInt(json, const [
        'expiringWithinSevenDays',
        'expiring_within_seven_days',
      ]),
      validityDays: readInt(json, const ['validityDays', 'validity_days']),
      reminderDays: readInt(json, const ['reminderDays', 'reminder_days']),
      programEnabled: readBool(json, const [
        'programEnabled',
        'program_enabled',
      ]),
      redemptionEnabled: readBool(json, const [
        'redemptionEnabled',
        'redemption_enabled',
      ]),
      spendOnDelivery: readBool(json, const [
        'spendOnDelivery',
        'spend_on_delivery',
      ]),
      spendOnServiceFee: readBool(json, const [
        'spendOnServiceFee',
        'spend_on_service_fee',
      ]),
    );
  }
}

enum LoyaltyTransactionType {
  openingBalance('OPENING_BALANCE'),
  earn('EARN'),
  spendReserve('SPEND_RESERVE'),
  spendCommit('SPEND_COMMIT'),
  spendRelease('SPEND_RELEASE'),
  spendRefund('SPEND_REFUND'),
  earnReversal('EARN_REVERSAL'),
  expire('EXPIRE'),
  debtRepayment('DEBT_REPAYMENT'),
  accountClosure('ACCOUNT_CLOSURE'),
  unknown('UNKNOWN');

  const LoyaltyTransactionType(this.value);
  final String value;

  factory LoyaltyTransactionType.fromJson(String? value) {
    return switch (value?.trim().toUpperCase()) {
      'OPENING_BALANCE' => LoyaltyTransactionType.openingBalance,
      'EARN' => LoyaltyTransactionType.earn,
      'SPEND_RESERVE' => LoyaltyTransactionType.spendReserve,
      'SPEND_COMMIT' => LoyaltyTransactionType.spendCommit,
      'SPEND_RELEASE' => LoyaltyTransactionType.spendRelease,
      'SPEND_REFUND' => LoyaltyTransactionType.spendRefund,
      'EARN_REVERSAL' => LoyaltyTransactionType.earnReversal,
      'EXPIRE' => LoyaltyTransactionType.expire,
      'DEBT_REPAYMENT' => LoyaltyTransactionType.debtRepayment,
      'ACCOUNT_CLOSURE' => LoyaltyTransactionType.accountClosure,
      _ => LoyaltyTransactionType.unknown,
    };
  }
}

class LoyaltyTransactionModel {
  LoyaltyTransactionModel({
    required this.id,
    required this.type,
    required this.availableDelta,
    required this.reservedDelta,
    required this.debtDelta,
    required this.availableBalanceAfter,
    required this.reservedBalanceAfter,
    required this.debtBalanceAfter,
    this.rawType,
    this.orderId,
    this.redemptionId,
    this.accrualId,
    this.creditLotId,
    this.expiresAt,
    this.createdAt,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) : metadata = Map<String, dynamic>.unmodifiable(metadata);

  final String id;
  final LoyaltyTransactionType type;
  final String? rawType;
  final int availableDelta;
  final int reservedDelta;
  final int debtDelta;
  final int availableBalanceAfter;
  final int reservedBalanceAfter;
  final int debtBalanceAfter;
  final String? orderId;
  final String? redemptionId;
  final String? accrualId;
  final String? creditLotId;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final Map<String, dynamic> metadata;

  int get displayDelta {
    return switch (type) {
      LoyaltyTransactionType.spendReserve => availableDelta,
      LoyaltyTransactionType.spendCommit => reservedDelta,
      LoyaltyTransactionType.spendRelease ||
      LoyaltyTransactionType.spendRefund => availableDelta,
      LoyaltyTransactionType.debtRepayment => -debtDelta,
      _ => availableDelta + reservedDelta - debtDelta,
    };
  }

  factory LoyaltyTransactionModel.fromJson(Map<String, dynamic> json) {
    final rawType =
        stringOrNull(json['type']) ?? stringOrNull(json['transaction_type']);
    return LoyaltyTransactionModel(
      id: readString(json, const ['id']),
      type: LoyaltyTransactionType.fromJson(rawType),
      rawType: rawType,
      availableDelta: readInt(json, const [
        'availableDelta',
        'available_delta',
      ]),
      reservedDelta: readInt(json, const ['reservedDelta', 'reserved_delta']),
      debtDelta: readInt(json, const ['debtDelta', 'debt_delta']),
      availableBalanceAfter: readInt(json, const [
        'availableBalanceAfter',
        'available_balance_after',
      ]),
      reservedBalanceAfter: readInt(json, const [
        'reservedBalanceAfter',
        'reserved_balance_after',
      ]),
      debtBalanceAfter: readInt(json, const [
        'debtBalanceAfter',
        'debt_balance_after',
      ]),
      orderId: stringOrNull(json['orderId']) ?? stringOrNull(json['order_id']),
      redemptionId:
          stringOrNull(json['redemptionId']) ??
          stringOrNull(json['redemption_id']),
      accrualId:
          stringOrNull(json['accrualId']) ?? stringOrNull(json['accrual_id']),
      creditLotId:
          stringOrNull(json['creditLotId']) ??
          stringOrNull(json['credit_lot_id']),
      expiresAt: readDateTime(json, const ['expiresAt', 'expires_at']),
      createdAt: readDateTime(json, const ['createdAt', 'created_at']),
      metadata: asJsonMap(json['metadata']),
    );
  }
}

class LoyaltyTransactionPageModel {
  LoyaltyTransactionPageModel({
    required List<LoyaltyTransactionModel> items,
    this.nextCursor,
  }) : items = List<LoyaltyTransactionModel>.unmodifiable(items);

  final List<LoyaltyTransactionModel> items;
  final String? nextCursor;

  factory LoyaltyTransactionPageModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyTransactionPageModel(
      items: asJsonMapList(
        json['items'],
      ).map(LoyaltyTransactionModel.fromJson).toList(growable: false),
      nextCursor:
          stringOrNull(json['nextCursor']) ?? stringOrNull(json['next_cursor']),
    );
  }
}

class CartLoyaltyPreviewModel {
  const CartLoyaltyPreviewModel({
    required this.balance,
    required this.spendableBalance,
    required this.debtAmount,
    required this.requestedPoints,
    required this.appliedPoints,
    required this.eligibleAmount,
    required this.maxPointsToSpend,
    required this.estimatedEarnPoints,
    required this.estimateOnly,
  });

  final int balance;
  final int spendableBalance;
  final int debtAmount;
  final int requestedPoints;
  final int appliedPoints;
  final int eligibleAmount;
  final int maxPointsToSpend;
  final int estimatedEarnPoints;
  final bool estimateOnly;

  factory CartLoyaltyPreviewModel.fromJson(Map<String, dynamic> json) {
    return CartLoyaltyPreviewModel(
      balance: readInt(json, const ['balance']),
      spendableBalance: readInt(json, const [
        'spendableBalance',
        'spendable_balance',
      ]),
      debtAmount: readInt(json, const ['debtAmount', 'debt_amount']),
      requestedPoints: readInt(json, const [
        'requestedPoints',
        'requested_points',
      ]),
      appliedPoints: readInt(json, const ['appliedPoints', 'applied_points']),
      eligibleAmount: readInt(json, const [
        'eligibleAmount',
        'eligible_amount',
      ]),
      maxPointsToSpend: readInt(json, const [
        'maxPointsToSpend',
        'max_points_to_spend',
      ]),
      estimatedEarnPoints: readInt(json, const [
        'estimatedEarnPoints',
        'estimated_earn_points',
      ]),
      estimateOnly: readBool(json, const ['estimateOnly', 'estimate_only']),
    );
  }
}

enum LoyaltyRedemptionStatus {
  reserved('RESERVED'),
  committed('COMMITTED'),
  released('RELEASED'),
  refunded('REFUNDED'),
  unknown('UNKNOWN');

  const LoyaltyRedemptionStatus(this.value);
  final String value;

  factory LoyaltyRedemptionStatus.fromJson(String? value) {
    return switch (value?.trim().toUpperCase()) {
      'RESERVED' => LoyaltyRedemptionStatus.reserved,
      'COMMITTED' => LoyaltyRedemptionStatus.committed,
      'RELEASED' => LoyaltyRedemptionStatus.released,
      'REFUNDED' => LoyaltyRedemptionStatus.refunded,
      _ => LoyaltyRedemptionStatus.unknown,
    };
  }
}

class LoyaltyRedemptionModel {
  const LoyaltyRedemptionModel({required this.amount, required this.status});

  final int amount;
  final LoyaltyRedemptionStatus status;

  factory LoyaltyRedemptionModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyRedemptionModel(
      amount: readInt(json, const ['amount']),
      status: LoyaltyRedemptionStatus.fromJson(stringOrNull(json['status'])),
    );
  }
}

enum LoyaltyAccrualStatus {
  pending('PENDING'),
  notEligible('NOT_ELIGIBLE'),
  earned('EARNED'),
  noReward('NO_REWARD'),
  reversed('REVERSED'),
  unknown('UNKNOWN');

  const LoyaltyAccrualStatus(this.value);
  final String value;

  factory LoyaltyAccrualStatus.fromJson(String? value) {
    return switch (value?.trim().toUpperCase()) {
      'PENDING' => LoyaltyAccrualStatus.pending,
      'NOT_ELIGIBLE' => LoyaltyAccrualStatus.notEligible,
      'EARNED' => LoyaltyAccrualStatus.earned,
      'NO_REWARD' => LoyaltyAccrualStatus.noReward,
      'REVERSED' => LoyaltyAccrualStatus.reversed,
      _ => LoyaltyAccrualStatus.unknown,
    };
  }
}

class LoyaltyAccrualModel {
  const LoyaltyAccrualModel({
    required this.status,
    required this.grossAmount,
    required this.debtRepaidAmount,
    required this.creditedAmount,
    this.id,
    this.campaignId,
    this.campaignName,
    this.earnedAt,
    this.expiresAt,
    this.reversedAt,
  });

  const LoyaltyAccrualModel.notEligible()
    : this(
        status: LoyaltyAccrualStatus.notEligible,
        grossAmount: 0,
        debtRepaidAmount: 0,
        creditedAmount: 0,
      );

  final String? id;
  final LoyaltyAccrualStatus status;
  final int grossAmount;
  final int debtRepaidAmount;
  final int creditedAmount;
  final String? campaignId;
  final String? campaignName;
  final DateTime? earnedAt;
  final DateTime? expiresAt;
  final DateTime? reversedAt;

  factory LoyaltyAccrualModel.fromJson(Map<String, dynamic> json) {
    return LoyaltyAccrualModel(
      id: stringOrNull(json['id']),
      status: LoyaltyAccrualStatus.fromJson(stringOrNull(json['status'])),
      grossAmount: readInt(json, const ['grossAmount', 'gross_amount']),
      debtRepaidAmount: readInt(json, const [
        'debtRepaidAmount',
        'debt_repaid_amount',
      ]),
      creditedAmount: readInt(json, const [
        'creditedAmount',
        'credited_amount',
      ]),
      campaignId:
          stringOrNull(json['campaignId']) ?? stringOrNull(json['campaign_id']),
      campaignName:
          stringOrNull(json['campaignName']) ??
          stringOrNull(json['campaign_name']),
      earnedAt: readDateTime(json, const ['earnedAt', 'earned_at']),
      expiresAt: readDateTime(json, const ['expiresAt', 'expires_at']),
      reversedAt: readDateTime(json, const ['reversedAt', 'reversed_at']),
    );
  }
}

class OrderLoyaltySummaryModel {
  const OrderLoyaltySummaryModel({
    required this.eligible,
    required this.accrual,
    this.redemption,
  });

  const OrderLoyaltySummaryModel.legacy()
    : this(eligible: false, accrual: const LoyaltyAccrualModel.notEligible());

  final bool eligible;
  final LoyaltyRedemptionModel? redemption;
  final LoyaltyAccrualModel accrual;

  factory OrderLoyaltySummaryModel.fromJson(Map<String, dynamic> json) {
    final redemption = asJsonMap(json['redemption']);
    final accrual = asJsonMap(json['accrual']);
    return OrderLoyaltySummaryModel(
      eligible: readBool(json, const ['eligible']),
      redemption: redemption.isEmpty
          ? null
          : LoyaltyRedemptionModel.fromJson(redemption),
      accrual: accrual.isEmpty
          ? const LoyaltyAccrualModel.notEligible()
          : LoyaltyAccrualModel.fromJson(accrual),
    );
  }
}
