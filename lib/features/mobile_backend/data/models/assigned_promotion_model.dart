import 'json_helpers.dart';

enum AssignedPromotionStatus {
  active('ACTIVE'),
  notStarted('NOT_STARTED'),
  used('USED'),
  expired('EXPIRED'),
  revoked('REVOKED'),
  inactive('INACTIVE'),
  globalLimitReached('GLOBAL_LIMIT_REACHED'),
  unknown('UNKNOWN');

  const AssignedPromotionStatus(this.value);

  final String value;

  bool get isUsable => this == AssignedPromotionStatus.active;

  factory AssignedPromotionStatus.fromJson(Object? value) {
    final normalized = value?.toString().trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) {
      return AssignedPromotionStatus.active;
    }
    return switch (normalized) {
      'ACTIVE' => AssignedPromotionStatus.active,
      'NOT_STARTED' => AssignedPromotionStatus.notStarted,
      'USED' => AssignedPromotionStatus.used,
      'EXPIRED' => AssignedPromotionStatus.expired,
      'REVOKED' => AssignedPromotionStatus.revoked,
      'INACTIVE' => AssignedPromotionStatus.inactive,
      'GLOBAL_LIMIT_REACHED' => AssignedPromotionStatus.globalLimitReached,
      _ => AssignedPromotionStatus.unknown,
    };
  }
}

/// A client-specific promotion assignment returned by
/// `GET /clients/me/promotions`.
///
/// Promotion rules have changed shape between backend versions. The parser
/// intentionally accepts both flattened assignments and assignments with a
/// nested `promotion` object, while exposing a stable model to the UI.
class AssignedPromotionModel {
  const AssignedPromotionModel({
    required this.id,
    required this.promotionAssignmentId,
    required this.promotionId,
    required this.code,
    required this.status,
    required this.title,
    required this.conditions,
    this.description,
    this.reward,
    this.startsAt,
    this.endsAt,
    this.remainingUses,
    this.raw = const <String, dynamic>{},
  });

  final String id;
  final String promotionAssignmentId;
  final String promotionId;
  final String code;
  final AssignedPromotionStatus status;
  final String title;
  final String? description;
  final List<String> conditions;
  final String? reward;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int? remainingUses;
  final Map<String, dynamic> raw;

  bool get canBeUsed => status.isUsable && code.trim().isNotEmpty;

  factory AssignedPromotionModel.fromJson(
    Map<String, dynamic> json, {
    String language = 'uz',
  }) {
    final promotion = asJsonMap(
      json['promotion'] ??
          json['promotionDetails'] ??
          json['promotion_details'],
    );
    final assignmentId = readString(json, const [
      'promotionAssignmentId',
      'promotion_assignment_id',
      'assignmentId',
      'assignment_id',
      'id',
    ]);
    final title = _localizedValue(
      _firstValue(promotion, const ['title', 'name']) ??
          _firstValue(json, const [
            'title',
            'promotionTitle',
            'promotion_title',
          ]),
      language,
    );
    final description = _optionalLocalizedValue(
      _firstValue(promotion, const ['description']) ??
          _firstValue(json, const ['description']),
      language,
    );
    final conditionsValue =
        _firstValue(json, const [
          'conditionsText',
          'conditions_text',
          'conditions',
          'condition',
        ]) ??
        _firstValue(promotion, const [
          'conditionsText',
          'conditions_text',
          'conditions',
          'condition',
        ]);
    final rewardValue =
        _firstValue(json, const ['rewardText', 'reward_text', 'reward']) ??
        _firstValue(promotion, const ['rewardText', 'reward_text', 'reward']);
    final reward =
        _rewardText(rewardValue, language) ?? _discountReward(json, promotion);

    return AssignedPromotionModel(
      id: readString(json, const ['id'], fallback: assignmentId),
      promotionAssignmentId: assignmentId,
      promotionId: readString(json, const [
        'promotionId',
        'promotion_id',
      ], fallback: readString(promotion, const ['id'])),
      code: readString(
        json,
        const ['code', 'promoCode', 'promo_code'],
        fallback: readString(promotion, const [
          'code',
          'promoCode',
          'promo_code',
        ]),
      ),
      status: AssignedPromotionStatus.fromJson(
        _firstValue(json, const [
          'status',
          'assignmentStatus',
          'assignment_status',
        ]),
      ),
      title: title,
      description: description,
      conditions: _displayLines(conditionsValue, language),
      reward: reward,
      startsAt:
          readDateTime(json, const ['startsAt', 'starts_at']) ??
          readDateTime(promotion, const ['startsAt', 'starts_at']),
      endsAt:
          readDateTime(json, const [
            'endsAt',
            'ends_at',
            'expiresAt',
            'expires_at',
          ]) ??
          readDateTime(promotion, const [
            'endsAt',
            'ends_at',
            'expiresAt',
            'expires_at',
          ]),
      remainingUses: _optionalInt(json, const [
        'remainingUses',
        'remaining_uses',
        'usesRemaining',
        'uses_remaining',
      ]),
      raw: Map<String, dynamic>.unmodifiable(json),
    );
  }
}

Object? _firstValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json[key] != null) return json[key];
  }
  return null;
}

String _localizedValue(Object? value, String language) {
  return _optionalLocalizedValue(value, language) ?? '';
}

String? _optionalLocalizedValue(Object? value, String language) {
  if (value is String) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
  if (value is num || value is bool) return value.toString();
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    for (final key in <String>[language, 'uz', 'ru', 'en', 'value']) {
      final localized = map[key];
      if (localized is String && localized.trim().isNotEmpty) {
        return localized.trim();
      }
    }
    for (final key in const ['text', 'label', 'title', 'name', 'description']) {
      final nested = _optionalLocalizedValue(map[key], language);
      if (nested != null) return nested;
    }
    if (map.length == 1) {
      return _optionalLocalizedValue(map.values.first, language);
    }
  }
  if (value is List) {
    final lines = _displayLines(value, language);
    return lines.isEmpty ? null : lines.join(' • ');
  }
  return null;
}

List<String> _displayLines(Object? value, String language) {
  if (value == null) return const <String>[];
  if (value is List) {
    return value
        .expand((entry) => _displayLines(entry, language))
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);
  }

  final direct = _optionalLocalizedValue(value, language);
  if (direct != null) return <String>[direct];

  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    final lines = <String>[];
    for (final entry in map.entries) {
      final displayValue = _ruleValue(entry.value, language);
      if (displayValue == null) continue;
      lines.add('${_humanize(entry.key)}: $displayValue');
    }
    return lines;
  }
  return const <String>[];
}

String? _ruleValue(Object? value, String language) {
  if (value is List) {
    final values = value
        .map((entry) => _ruleValue(entry, language))
        .whereType<String>()
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    return values.isEmpty ? null : values.join(', ');
  }
  return _optionalLocalizedValue(value, language);
}

String _humanize(String value) {
  final separated = value
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)}',
      )
      .replaceAll('_', ' ')
      .trim();
  if (separated.isEmpty) return value;
  return '${separated[0].toUpperCase()}${separated.substring(1)}';
}

String? _discountReward(
  Map<String, dynamic> assignment,
  Map<String, dynamic> promotion,
) {
  final type =
      stringOrNull(assignment['discountType']) ??
      stringOrNull(assignment['discount_type']) ??
      stringOrNull(promotion['discountType']) ??
      stringOrNull(promotion['discount_type']);
  final value =
      _optionalInt(assignment, const ['discountValue', 'discount_value']) ??
      _optionalInt(promotion, const ['discountValue', 'discount_value']);
  if (value == null) return null;
  return _isPercentageRewardType(type) ? '$value%' : value.toString();
}

String? _rewardText(Object? value, String language) {
  final direct = _optionalLocalizedValue(value, language);
  if (direct != null) return direct;
  if (value is! Map) return null;

  final map = Map<String, dynamic>.from(value);
  final type =
      stringOrNull(map['type']) ??
      stringOrNull(map['discountType']) ??
      stringOrNull(map['discount_type']);
  final amount = _optionalInt(map, const [
    'value',
    'amount',
    'discountValue',
    'discount_value',
  ]);
  if (amount == null) return null;
  return _isPercentageRewardType(type) ? '$amount%' : amount.toString();
}

bool _isPercentageRewardType(String? type) {
  final normalized = type?.trim().toUpperCase();
  return normalized == 'PERCENT' || normalized == 'PERCENTAGE';
}

int? _optionalInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
  }
  return null;
}
