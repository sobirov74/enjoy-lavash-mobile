import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/ordering_status_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'parses seven weekly rows and independent pickup and delivery states',
    () {
      final status = OrderingStatusModel.fromJson(_orderingStatusJson());

      expect(status.branchId, 'branch-chilanzar');
      expect(status.timezone, 'Asia/Tashkent');
      expect(status.evaluatedAt, DateTime.utc(2026, 8, 10, 18, 15));
      expect(status.evaluatedAt.isUtc, isTrue);
      expect(status.weeklyHours, hasLength(7));

      expect(status.weeklyHours.first.weekday, DateTime.monday);
      expect(status.weeklyHours.first.opensAt, '09:00');
      expect(status.weeklyHours.first.closesAt, '24:00');
      expect(status.weeklyHours.first.deliveryOpensAt, '10:00');
      expect(status.weeklyHours.first.deliveryClosesAt, '23:00');
      expect(status.weeklyHours.first.source, WorkingHourSource.branch);
      expect(status.weeklyHours[3].source, WorkingHourSource.organisation);
      expect(status.weeklyHours[5].source, WorkingHourSource.default24Hours);
      expect(status.weeklyHours.last.isClosed, isTrue);

      expect(status.pickup.isOpen, isTrue);
      expect(status.pickup.closureSource, isNull);
      expect(status.pickup.nextOpeningAt, isNull);
      expect(status.pickup.weeklySource, WorkingHourSource.branch);

      expect(status.delivery.isOpen, isFalse);
      expect(status.delivery.closureSource, ClosureSource.outsideHours);
      expect(status.delivery.nextOpeningAt, DateTime.utc(2026, 8, 11, 5));
      expect(status.delivery.nextOpeningAt?.isUtc, isTrue);
      expect(status.delivery.localDate, '2026-08-10');
      expect(status.delivery.weekday, DateTime.monday);
    },
  );

  test('keeps unknown server enum values typed and forward compatible', () {
    final payload = _orderingStatusJson();
    final weeklyHours = payload['weeklyHours']! as List<Map<String, Object?>>;
    weeklyHours.first['source'] = 'FUTURE_SOURCE';
    final delivery = payload['delivery']! as Map<String, Object?>;
    delivery['closureSource'] = 'FUTURE_CLOSURE';

    final status = OrderingStatusModel.fromJson(payload);

    expect(status.weeklyHours.first.source, WorkingHourSource.unknown);
    expect(status.delivery.closureSource, ClosureSource.unknown);
  });

  test('parses ordering-closed metadata aliases and UTC instants', () {
    final metadata = OrderingClosedMetadataModel.fromJson({
      'branch_id': 'branch-yunusabad',
      'order_type': 'DELIVERY',
      'check_kind': 'SCHEDULED',
      'timezone': 'Asia/Tashkent',
      'closure_source': 'BRANCH_DAY_OFF',
      'evaluated_at': '2026-09-02T12:00:00+05:00',
      'next_opening_at': '2026-09-03T09:00:00+05:00',
    });

    expect(metadata.branchId, 'branch-yunusabad');
    expect(metadata.orderType, 'DELIVERY');
    expect(metadata.checkKind, OrderingCheckKind.scheduled);
    expect(metadata.closureSource, ClosureSource.branchDayOff);
    expect(metadata.evaluatedAt, DateTime.utc(2026, 9, 2, 7));
    expect(metadata.nextOpeningAt, DateTime.utc(2026, 9, 3, 4));
  });
}

Map<String, Object?> _orderingStatusJson() {
  return {
    'branchId': 'branch-chilanzar',
    'timezone': 'Asia/Tashkent',
    'evaluatedAt': '2026-08-10T18:15:00.000Z',
    'weeklyHours': <Map<String, Object?>>[
      _workingHour(weekday: 1, source: 'BRANCH'),
      _workingHour(weekday: 2, source: 'BRANCH'),
      _workingHour(weekday: 3, source: 'BRANCH'),
      _workingHour(weekday: 4, source: 'ORGANISATION'),
      _workingHour(weekday: 5, source: 'ORGANISATION'),
      _workingHour(
        weekday: 6,
        source: 'DEFAULT_24_HOURS',
        opensAt: '00:00',
        deliveryOpensAt: '00:00',
        closesAt: '24:00',
        deliveryClosesAt: '24:00',
      ),
      _workingHour(
        weekday: 7,
        source: 'ORGANISATION',
        opensAt: '00:00',
        deliveryOpensAt: '00:00',
        closesAt: '00:00',
        deliveryClosesAt: '00:00',
        isClosed: true,
      ),
    ],
    'pickup': {
      'isOpen': true,
      'evaluatedAt': '2026-08-10T18:15:00.000Z',
      'timezone': 'Asia/Tashkent',
      'localDate': '2026-08-10',
      'weekday': 1,
      'weeklySource': 'BRANCH',
      'closureSource': null,
      'nextOpeningAt': null,
    },
    'delivery': {
      'isOpen': false,
      'evaluatedAt': '2026-08-10T18:15:00.000Z',
      'timezone': 'Asia/Tashkent',
      'localDate': '2026-08-10',
      'weekday': 1,
      'weeklySource': 'BRANCH',
      'closureSource': 'OUTSIDE_HOURS',
      'nextOpeningAt': '2026-08-11T05:00:00.000Z',
    },
  };
}

Map<String, Object?> _workingHour({
  required int weekday,
  required String source,
  String opensAt = '09:00',
  String closesAt = '24:00',
  String deliveryOpensAt = '10:00',
  String deliveryClosesAt = '23:00',
  bool isClosed = false,
}) {
  return {
    'weekday': weekday,
    'opensAt': opensAt,
    'closesAt': closesAt,
    'isClosed': isClosed,
    'deliveryOpensAt': deliveryOpensAt,
    'deliveryClosesAt': deliveryClosesAt,
    'source': source,
  };
}
