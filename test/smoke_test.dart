import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuelguard_mobile_app/dashboard/presentation/views/dashboard/dashboard.dart';
import 'package:fuelguard_mobile_app/app.dart';
import 'package:fuelguard_mobile_app/app_config.dart';
import 'package:fuelguard_mobile_app/app_routes.dart';
import 'package:fuelguard_mobile_app/shared/infrastructure/format.dart';
import 'package:fuelguard_mobile_app/shared/infrastructure/route_match.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('format and route matching', () {
    expect(formatMoney(1234.5), 'S/ 1,234.50');
    expect(formatDate('2026-03-05T10:00:00'), '05/03/2026');
    expect(
      matchPath('/ordering/order-detail/:id', '/ordering/order-detail/12'),
      {'id': '12'},
    );
    expect(matchPath('/a', '/b'), isNull);
  });

  testWidgets('app boots, bypass login reaches dashboard with guards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412 * 2, 892 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final config = (await tester.runAsync(AppConfig.create))!;
    await tester.pumpWidget(App(config: config));
    await tester.pumpAndSettle();
    expect(
      find.text('Demo mode (bypass)'),
      findsOneWidget,
    ); // arranque directo en login
    expect(resolveUrl('/', config.iamStore).url, '/login');
    expect(resolveUrl('/home', config.iamStore).url, '/login');

    // Guard: sin sesión, /dashboard redirige a login con returnUrl.
    expect(
      resolveUrl('/dashboard', config.iamStore).url,
      startsWith('/login?returnUrl='),
    );

    await tester.tap(find.text('Demo mode (bypass)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buyer'));
    await tester.pumpAndSettle();
    expect(find.byType(Dashboard), findsOneWidget);
    expect(config.iamStore.isBuyer, isTrue);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
    expect(resolveUrl('/', config.iamStore).url, '/dashboard');
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsWidgets);
    await tester.pump(const Duration(seconds: 1));
    expect(resolveUrl('/payments', config.iamStore).url, '/access-denied');
    expect(
      resolveUrl('/ordering', config.iamStore).url,
      '/ordering/request-list',
    );

    // Demo HTTP: perfil de la empresa.
    final res = await tester.runAsync(
      () => config.httpClient.getJson(
        'https://fuelguard-backend.onrender.com/api/buyer-companies/10',
      ),
    );
    expect(res!.statusCode, 200);
    expect(res.body, contains('Minera Andina'));
  });
}
