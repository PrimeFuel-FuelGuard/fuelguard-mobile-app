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
}
