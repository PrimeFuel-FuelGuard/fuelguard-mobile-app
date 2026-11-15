import 'package:material_ui/material_ui.dart';

import '../../iam/application/iam_store.dart';
import '../domain/model/analytics_entity.dart';
import '../domain/sales_trend.dart';
import '../infrastructure/analytics_api.dart';

/// Variante de análisis según el rol del usuario.
enum AnalyticsKind { buyer, provider, admin }

/// Indicador: [label] es clave i18n; [money] indica formato de moneda.
class AnalyticsKpi {
  const AnalyticsKpi({
    required this.label,
    required this.value,
    this.money = false,
  });

  final String label;
  final num value;
  final bool money;
}

/// Análisis por rol (equivale a `analytics.ts`) con rango de fechas y tendencia de ventas.
///
/// Por defecto el rango va del primer día del mes anterior a hoy (America/Lima).
class AnalyticsStore extends ChangeNotifier {
  AnalyticsStore(this._api, this._iam) : _to = _limaDay() {
    _from = DateTime(_to.year, _to.month - 1, 1);
  }

  final AnalyticsApi _api;
  final IamStore _iam;
  late DateTime _from;
  DateTime _to;
  String _granularity = TrendGranularity.day;
  BuyerAnalytics? _buyer;
  ProviderAnalytics? _provider;
  PlatformSummary? _platform;
  bool _loading = true;
  bool _error = false;

  AnalyticsKind get kind => _iam.isAdmin
      ? AnalyticsKind.admin
      : _iam.isProvider
      ? AnalyticsKind.provider
      : AnalyticsKind.buyer;
  DateTime get from => _from;
  DateTime get to => _to;
  String get granularity => _granularity;
  bool get loading => _loading;
  bool get error => _error;
  BuyerAnalytics? get buyer => _buyer;
  ProviderAnalytics? get provider => _provider;
  PlatformSummary? get platform => _platform;

  /// Serie mensual dentro del rango, en orden cronológico.
  List<MonthlyAmount> get monthly {
    final rows = switch (kind) {
      AnalyticsKind.buyer => _buyer?.monthlySpending ?? const <MonthlyAmount>[],
      AnalyticsKind.provider =>
        _provider?.monthlyRevenue ?? const <MonthlyAmount>[],
      AnalyticsKind.admin => const <MonthlyAmount>[],
    };
    final fromMonth = _iso(_from).substring(0, 7);
    final toMonth = _iso(_to).substring(0, 7);
    return [
      for (final row in rows)
        if (row.month.compareTo(fromMonth) >= 0 &&
            row.month.compareTo(toMonth) <= 0)
          row,
    ]..sort((a, b) => a.month.compareTo(b.month));
  }

  /// Los cinco meses con mayor monto.
  List<MonthlyAmount> get topMonths => ([
    ...monthly,
  ]..sort((a, b) => b.amount.compareTo(a.amount))).take(5).toList();

  /// Tendencia de litros agrupada por día, semana o mes (solo proveedor).
  List<SalesTrendPoint> get trend {
    final p = _provider;
    return p == null
        ? const []
        : groupSalesTrend(p.salesTrend, _granularity, _iso(_from), _iso(_to));
  }

  bool get hasSales => trend.any((point) => point.litres > 0);

  List<AnalyticsKpi> get kpis {
    final b = _buyer;
    final p = _provider;
    final s = _platform;
    return switch (kind) {
      AnalyticsKind.buyer when b != null => [
        AnalyticsKpi(label: 'analytics.total-orders', value: b.totalOrders),
        AnalyticsKpi(
          label: 'analytics.total-spent',
          value: b.totalSpent,
          money: true,
        ),
        AnalyticsKpi(
          label: 'analytics.completed-payments',
          value: b.completedPayments,
        ),
        AnalyticsKpi(
          label: 'analytics.pending-payments',
          value: b.pendingPayments,
        ),
      ],
      AnalyticsKind.provider when p != null => [
        AnalyticsKpi(label: 'analytics.total-orders', value: p.totalOrders),
        AnalyticsKpi(
          label: 'analytics.confirmed-orders',
          value: p.confirmedOrders,
        ),
        AnalyticsKpi(
          label: 'analytics.cancelled-orders',
          value: p.cancelledOrders,
        ),
        AnalyticsKpi(
          label: 'analytics.total-revenue',
          value: p.totalRevenue,
          money: true,
        ),
      ],
      AnalyticsKind.admin when s != null => [
        AnalyticsKpi(label: 'analytics.total-orders', value: s.totalOrders),
        AnalyticsKpi(label: 'analytics.pending-orders', value: s.pendingOrders),
        AnalyticsKpi(
          label: 'analytics.total-deliveries',
          value: s.totalDeliveries,
        ),
        AnalyticsKpi(
          label: 'analytics.completed-deliveries',
          value: s.completedDeliveries,
        ),
        AnalyticsKpi(label: 'analytics.total-payments', value: s.totalPayments),
        AnalyticsKpi(
          label: 'analytics.total-revenue',
          value: s.totalRevenue,
          money: true,
        ),
      ],
      _ => const [],
    };
  }

  Future<void> load() async {
    _error = false;
    final id = kind == AnalyticsKind.buyer ? _iam.companyId : _iam.providerId;
    if (kind != AnalyticsKind.admin && id == null) {
      _loading = false;
      _error = true;
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    try {
      switch (kind) {
        case AnalyticsKind.admin:
          _platform = await _api.getPlatformSummary();
        case AnalyticsKind.buyer:
          _buyer = await _api.getBuyerAnalytics(id!);
        case AnalyticsKind.provider:
          _provider = await _api.getProviderAnalytics(
            id!,
            _iso(_from),
            _iso(_to),
          );
      }
    } catch (_) {
      _error = true;
    }
    _loading = false;
    notifyListeners();
  }

  void setFrom(DateTime value) {
    _from = value;
    _onRangeChanged();
  }

  void setTo(DateTime value) {
    _to = value;
    _onRangeChanged();
  }

  void setGranularity(String value) {
    _granularity = value;
    notifyListeners();
  }

  /// Solo el proveedor recibe el rango en la API; el comprador lo aplica a la serie local.
  void _onRangeChanged() {
    if (kind == AnalyticsKind.provider) {
      load();
    } else {
      notifyListeners();
    }
  }
}

/// Hoy en America/Lima (UTC-5, sin horario de verano) a medianoche.
DateTime _limaDay() {
  final lima = DateTime.now().toUtc().subtract(const Duration(hours: 5));
  return DateTime(lima.year, lima.month, lima.day);
}

String _iso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
