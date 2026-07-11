import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/core/services/mobile_push_notification_service.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/branch_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/catalog_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/entities/mobile_bootstrap.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/domain/repositories/mobile_backend_repository.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/screens/branch_bottom_sheet.dart';
import 'package:enjoy_lavash_mobile/theme/light_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('marks and returns the selected pickup branch', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const branches = <BranchModel>[
      BranchModel(
        id: 'chilanzar',
        name: 'Chilanzar',
        address: 'Bunyodkor Avenue',
        isActive: true,
      ),
      BranchModel(
        id: 'yunusabad',
        name: 'Yunusabad',
        address: 'Amir Temur Avenue',
        isActive: true,
      ),
      BranchModel(id: 'closed', name: 'Closed branch', isActive: false),
    ];
    final controller = MobileBackendController(
      _BranchRepository(branches),
      MobilePushNotificationService(ApiClient()),
    );
    addTearDown(controller.dispose);
    await controller.bootstrap(language: 'en');

    String? selectedBranchId = 'yunusabad';
    BranchModel? selectedBranch;

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: ChangeNotifierProvider<MobileBackendController>.value(
          value: controller,
          child: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () async {
                      final branch = await showBranchBottomSheet(
                        context,
                        selectedBranchId: selectedBranchId,
                      );
                      if (branch == null) return;
                      setState(() {
                        selectedBranch = branch;
                        selectedBranchId = branch.id;
                      });
                    },
                    child: const Text('Choose branch'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Choose branch'));
    await tester.pumpAndSettle();

    expect(find.text('Closed branch'), findsNothing);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(
      tester
          .widget<Semantics>(
            find.byKey(const ValueKey<String>('branch-card-yunusabad')),
          )
          .properties
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<Semantics>(
            find.byKey(const ValueKey<String>('branch-card-chilanzar')),
          )
          .properties
          .selected,
      isFalse,
    );

    await tester.tap(find.text('Chilanzar'));
    await tester.pumpAndSettle();

    expect(selectedBranch?.id, 'chilanzar');

    await tester.tap(find.text('Choose branch'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Semantics>(
            find.byKey(const ValueKey<String>('branch-card-chilanzar')),
          )
          .properties
          .selected,
      isTrue,
    );
  });
}

class _BranchRepository implements MobileBackendRepository {
  const _BranchRepository(this.branches);

  final List<BranchModel> branches;

  @override
  Future<Result<MobileBootstrap>> bootstrap({
    required String language,
    String? branchId,
  }) async {
    return Success(
      MobileBootstrap(
        branches: branches,
        catalog: CatalogModel.fromJson(const <String, dynamic>{}),
        promotions: const [],
        paymentMethods: const [],
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnsupportedError('${invocation.memberName} is not implemented');
  }
}
