import 'json_helpers.dart';

enum WorkingHourSource {
  branch('BRANCH'),
  organisation('ORGANISATION'),
  default24Hours('DEFAULT_24_HOURS'),
  unknown('UNKNOWN');

  const WorkingHourSource(this.value);

  final String value;

  factory WorkingHourSource.fromJson(Object? value) {
    return switch (value?.toString().trim().toUpperCase()) {
      'BRANCH' => WorkingHourSource.branch,
      'ORGANISATION' => WorkingHourSource.organisation,
      'DEFAULT_24_HOURS' => WorkingHourSource.default24Hours,
      _ => WorkingHourSource.unknown,
    };
  }
}

enum ClosureSource {
  branchDayOff('BRANCH_DAY_OFF'),
  organisationDayOff('ORGANISATION_DAY_OFF'),
  weeklyClosed('WEEKLY_CLOSED'),
  outsideHours('OUTSIDE_HOURS'),
  unknown('UNKNOWN');

  const ClosureSource(this.value);

  final String value;

  factory ClosureSource.fromJson(Object? value) {
    return switch (value?.toString().trim().toUpperCase()) {
      'BRANCH_DAY_OFF' => ClosureSource.branchDayOff,
      'ORGANISATION_DAY_OFF' => ClosureSource.organisationDayOff,
      'WEEKLY_CLOSED' => ClosureSource.weeklyClosed,
      'OUTSIDE_HOURS' => ClosureSource.outsideHours,
      _ => ClosureSource.unknown,
    };
  }
}

class EffectiveWorkingHourModel {
  const EffectiveWorkingHourModel({
    required this.weekday,
    required this.opensAt,
    required this.closesAt,
    required this.isClosed,
    required this.deliveryOpensAt,
    required this.deliveryClosesAt,
    required this.source,
  });

  final int weekday;
  final String opensAt;
  final String closesAt;
  final bool isClosed;
  final String deliveryOpensAt;
  final String deliveryClosesAt;
  final WorkingHourSource source;

  factory EffectiveWorkingHourModel.fromJson(Map<String, dynamic> json) {
    return EffectiveWorkingHourModel(
      weekday: readInt(json, const ['weekday']),
      opensAt: readString(json, const ['opensAt']),
      closesAt: readString(json, const ['closesAt']),
      isClosed: readBool(json, const ['isClosed']),
      deliveryOpensAt: readString(json, const ['deliveryOpensAt']),
      deliveryClosesAt: readString(json, const ['deliveryClosesAt']),
      source: WorkingHourSource.fromJson(json['source']),
    );
  }
}

class OrderingAvailabilityModel {
  const OrderingAvailabilityModel({
    required this.isOpen,
    required this.evaluatedAt,
    required this.timezone,
    required this.localDate,
    required this.weekday,
    required this.weeklySource,
    required this.closureSource,
    required this.nextOpeningAt,
  });

  final bool isOpen;
  final DateTime evaluatedAt;
  final String timezone;
  final String localDate;
  final int weekday;
  final WorkingHourSource weeklySource;
  final ClosureSource? closureSource;
  final DateTime? nextOpeningAt;

  factory OrderingAvailabilityModel.fromJson(Map<String, dynamic> json) {
    final closureSource = json['closureSource'];
    return OrderingAvailabilityModel(
      isOpen: readBool(json, const ['isOpen']),
      evaluatedAt: _requiredUtcDateTime(json, 'evaluatedAt'),
      timezone: readString(json, const ['timezone']),
      localDate: readString(json, const ['localDate']),
      weekday: readInt(json, const ['weekday']),
      weeklySource: WorkingHourSource.fromJson(json['weeklySource']),
      closureSource: closureSource == null
          ? null
          : ClosureSource.fromJson(closureSource),
      nextOpeningAt: readDateTime(json, const ['nextOpeningAt'])?.toUtc(),
    );
  }
}

class OrderingStatusModel {
  const OrderingStatusModel({
    required this.branchId,
    required this.timezone,
    required this.evaluatedAt,
    required this.weeklyHours,
    required this.pickup,
    required this.delivery,
  });

  final String branchId;
  final String timezone;
  final DateTime evaluatedAt;
  final List<EffectiveWorkingHourModel> weeklyHours;
  final OrderingAvailabilityModel pickup;
  final OrderingAvailabilityModel delivery;

  factory OrderingStatusModel.fromJson(Map<String, dynamic> json) {
    return OrderingStatusModel(
      branchId: readString(json, const ['branchId']),
      timezone: readString(json, const ['timezone']),
      evaluatedAt: _requiredUtcDateTime(json, 'evaluatedAt'),
      weeklyHours: List<EffectiveWorkingHourModel>.unmodifiable(
        asJsonMapList(
          json['weeklyHours'],
        ).map(EffectiveWorkingHourModel.fromJson),
      ),
      pickup: OrderingAvailabilityModel.fromJson(asJsonMap(json['pickup'])),
      delivery: OrderingAvailabilityModel.fromJson(asJsonMap(json['delivery'])),
    );
  }
}

enum OrderingCheckKind {
  current('CURRENT'),
  scheduled('SCHEDULED'),
  unknown('UNKNOWN');

  const OrderingCheckKind(this.value);

  final String value;

  factory OrderingCheckKind.fromJson(Object? value) {
    return switch (value?.toString().trim().toUpperCase()) {
      'CURRENT' => OrderingCheckKind.current,
      'SCHEDULED' => OrderingCheckKind.scheduled,
      _ => OrderingCheckKind.unknown,
    };
  }
}

class OrderingClosedMetadataModel {
  const OrderingClosedMetadataModel({
    required this.branchId,
    required this.orderType,
    required this.checkKind,
    required this.timezone,
    required this.closureSource,
    required this.evaluatedAt,
    required this.nextOpeningAt,
  });

  final String branchId;
  final String orderType;
  final OrderingCheckKind checkKind;
  final String timezone;
  final ClosureSource closureSource;
  final DateTime? evaluatedAt;
  final DateTime? nextOpeningAt;

  factory OrderingClosedMetadataModel.fromJson(Map<String, dynamic> json) {
    return OrderingClosedMetadataModel(
      branchId: readString(json, const ['branchId', 'branch_id']),
      orderType: readString(json, const ['orderType', 'order_type']),
      checkKind: OrderingCheckKind.fromJson(
        json['checkKind'] ?? json['check_kind'],
      ),
      timezone: readString(json, const ['timezone']),
      closureSource: ClosureSource.fromJson(
        json['closureSource'] ?? json['closure_source'],
      ),
      evaluatedAt: readDateTime(json, const [
        'evaluatedAt',
        'evaluated_at',
      ])?.toUtc(),
      nextOpeningAt: readDateTime(json, const [
        'nextOpeningAt',
        'next_opening_at',
      ])?.toUtc(),
    );
  }
}

DateTime _requiredUtcDateTime(Map<String, dynamic> json, String key) {
  final value = readDateTime(json, [key]);
  if (value == null) {
    throw FormatException('Missing or invalid $key');
  }
  return value.toUtc();
}
