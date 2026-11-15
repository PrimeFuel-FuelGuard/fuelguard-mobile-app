import '../../../shared/infrastructure/demo/demo_handler.dart';
import '../../../shared/infrastructure/demo/demo_world.dart';

const double _pricePerLitre = 16.2;

double _money(double value) => (value * 100).roundToDouble() / 100;

/// Ventas diarias de PetroSur del 1 oct al 15 nov 2026: días hábiles, sábados y algunos domingos.
final List<({String date, double litres})> _dailySales = () {
  final out = <({String date, double litres})>[];
  final end = DateTime.utc(2026, 11, 15);
  var day = DateTime.utc(2026, 10, 1);
  for (
    var i = 0;
    !day.isAfter(end);
    i++, day = day.add(const Duration(days: 1))
  ) {
    final litres = switch (day.weekday) {
      <= 5 => 1200 + (i * 1373) % 1800,
      6 => 600 + (i * 911) % 900,
      _ => 0,
    };
    if (litres > 0) {
      final date = day.toIso8601String().substring(0, 10);
      out.add((date: date, litres: litres.toDouble()));
    }
  }
  return out;
}();

bool _inRange(String date, String? from, String? to) =>
    (from == null || date.compareTo(from) >= 0) &&
    (to == null || date.compareTo(to) <= 0);

Map<String, dynamic> _providerAnalytics(
  int providerId,
  String? from,
  String? to,
) {
  if (providerId != DemoWorld.providerId) {
    return {
      'providerId': providerId,
      'totalOrders': 0,
      'confirmedOrders': 0,
      'cancelledOrders': 0,
      'totalRevenue': 0.0,
      'monthlyRevenue': <Map<String, dynamic>>[],
      'pendingOrders': 0,
      'totalFuelSoldLitres': 0.0,
      'salesTrend': <Map<String, dynamic>>[],
    };
  }
  final days = [
    for (final d in _dailySales)
      if (_inRange(d.date, from, to)) d,
  ];
  final litresByMonth = <String, double>{};
  for (final d in days) {
    final month = d.date.substring(0, 7);
    litresByMonth[month] = (litresByMonth[month] ?? 0) + d.litres;
  }
  final monthly = [
    for (final e in litresByMonth.entries)
      {
        'month': e.key,
        'monthIndex': int.parse(e.key.substring(5)),
        'amount': _money(e.value * _pricePerLitre),
      },
  ];
  return {
    'providerId': providerId,
    'totalOrders': 48,
    'confirmedOrders': 39,
    'cancelledOrders': 4,
    'totalRevenue': _money(
      monthly.fold(0, (sum, m) => sum + (m['amount'] as double)),
    ),
    'monthlyRevenue': monthly,
    'pendingOrders': 5,
    'totalFuelSoldLitres': days.fold(0.0, (sum, d) => sum + d.litres),
    'salesTrend': [
      for (final d in days) {'date': d.date, 'litres': d.litres},
    ],
  };
}

final Map<int, Map<String, dynamic>> _buyers = {
  DemoWorld.buyerCompanyId: {
    'totalOrders': 22,
    'totalSpent': 510960.00,
    'completedPayments': 9,
    'pendingPayments': 2,
    'monthlySpending': [
      {'month': '2026-10', 'monthIndex': 10, 'amount': 214560.00},
      {'month': '2026-11', 'monthIndex': 11, 'amount': 296400.00},
    ],
  },
  DemoWorld.buyer2CompanyId: {
    'totalOrders': 6,
    'totalSpent': 120320.00,
    'completedPayments': 3,
    'pendingPayments': 1,
    'monthlySpending': [
      {'month': '2026-10', 'monthIndex': 10, 'amount': 58400.00},
      {'month': '2026-11', 'monthIndex': 11, 'amount': 61920.00},
    ],
  },
};

final Map<String, dynamic> _platform = {
  'totalOrders': 96,
  'totalDeliveries': 71,
  'totalPayments': 88,
  'totalRevenue': 4850320.00,
  'pendingOrders': 9,
  'completedDeliveries': 58,
};

/// Datos demo de analytics: análisis de proveedor (ventas diarias), comprador y resumen de plataforma.
class AnalyticsDemoHandler implements DemoHandler {
  @override
  Future<DemoResponse?> handle(DemoRequest r) async {
    final provider = r.match('GET', '/analytics/providers/:id');
    if (provider != null) {
      final id = int.tryParse(provider['id']!);
      if (id == null ||
          (id != DemoWorld.providerId &&
              id != DemoWorld.provider21Id &&
              id != DemoWorld.provider22Id)) {
        return DemoResponse.error(404, 'Provider not found');
      }
      return DemoResponse.json(
        _providerAnalytics(id, r.query['from'], r.query['to']),
      );
    }

    final buyer = r.match('GET', '/analytics/buyers/:id');
    if (buyer != null) {
      final id = int.tryParse(buyer['id']!);
      final data = id == null ? null : _buyers[id];
      return data == null
          ? DemoResponse.error(404, 'Company not found')
          : DemoResponse.json(data);
    }

    if (r.match('GET', '/analytics/platform') != null) {
      return DemoResponse.json(_platform);
    }
    return null;
  }
}
