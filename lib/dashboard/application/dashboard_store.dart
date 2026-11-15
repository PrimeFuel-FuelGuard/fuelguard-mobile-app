import 'package:material_ui/material_ui.dart';

import '../../analytics/domain/model/analytics_entity.dart';
import '../../analytics/domain/sales_trend.dart';
import '../../analytics/infrastructure/analytics_api.dart';
import '../../equipment/domain/model/provider_equipment_entity.dart';
import '../../equipment/infrastructure/provider_equipment_api.dart';
import '../../fulfillment/domain/model/provider_delivery_entity.dart';
import '../../fulfillment/infrastructure/fulfillment_api.dart';
import '../../iam/application/iam_store.dart';
import '../../ordering/domain/model/order_entity.dart';
import '../../ordering/domain/model/request_entity.dart';
import '../../ordering/infrastructure/ordering_api.dart';

const int _criticalLimit = 5;

/// Carga independiente por tarjeta: una falla no oculta el resto del panel.
class CardState<T> {
  const CardState({
    this.loading = true,
    this.error = false,
    this.data = const [],
  });

  final bool loading;
  final bool error;
  final List<T> data;
}

/// Indicador del resumen: [label] es clave i18n; [money] indica formato de moneda.
class DashboardKpi {
  const DashboardKpi({
    required this.label,
    required this.value,
    this.money = false,
  });

  final String label;
  final num value;
  final bool money;
}

/// Resumen operativo de comprador y proveedor (equivale a `dashboard.ts`).
///
/// Reúne datos de otros contextos (ordering, analytics, equipment, fulfillment) igual que el
/// componente Angular; el análisis mensual vive en `/analytics`.
class DashboardStore extends ChangeNotifier {
  DashboardStore(
    this._analytics,
    this._ordering,
    this._equipment,
    this._fulfillment,
    this._iam,
  );

  final AnalyticsApi _analytics;
  final OrderingApi _ordering;
  final ProviderEquipmentApi _equipment;
  final FulfillmentApi _fulfillment;
  final IamStore _iam;

  final String _today = _limaToday();
  late final String _monthStart = '${_today.substring(0, 8)}01';

  BuyerAnalytics? _buyer;
  ProviderAnalytics? _provider;
  bool _loading = true;
  bool _error = false;
  List<Order> _orders = [];
  bool _ordersLoading = false;
  bool _ordersError = false;
  List<Request> _pendingRequests = [];
  bool _inboxLoading = false;
  bool _inboxError = false;
  CardState<ProviderTank> _criticalTanks = const CardState();
  CardState<ProviderDelivery> _todayDeliveries = const CardState();
  String _granularity = TrendGranularity.day;
  int _analyticsSeq = 0;
  int _ordersSeq = 0;
  int _inboxSeq = 0;

  bool get isBuyer => _iam.isBuyer;
  BuyerAnalytics? get buyer => _buyer;
  ProviderAnalytics? get provider => _provider;
  bool get loading => _loading;
  bool get error => _error;
  List<Order> get orders => _orders;
  bool get ordersLoading => _ordersLoading;
  bool get ordersError => _ordersError;
  List<Request> get pendingRequests => _pendingRequests;
  bool get inboxLoading => _inboxLoading;
  bool get inboxError => _inboxError;
  CardState<ProviderTank> get criticalTanks => _criticalTanks;
  CardState<ProviderDelivery> get todayDeliveries => _todayDeliveries;
  String get granularity => _granularity;

  List<DashboardKpi> get kpis {
    final b = _buyer;
    final p = _provider;
    if (isBuyer) {
      if (b == null) return const [];
      return [
        DashboardKpi(
          label: 'analytics.total-spent',
          value: b.totalSpent,
          money: true,
        ),
        DashboardKpi(
          label: 'analytics.pending-payments',
          value: b.pendingPayments,
        ),
        DashboardKpi(label: 'analytics.total-orders', value: b.totalOrders),
        DashboardKpi(
          label: 'analytics.completed-payments',
          value: b.completedPayments,
        ),
      ];
    }
    if (p == null) return const [];
    return [
      DashboardKpi(
        label: 'analytics.total-revenue',
        value: p.totalRevenue,
        money: true,
      ),
      DashboardKpi(label: 'analytics.fuel-sold', value: p.totalFuelSoldLitres),
      DashboardKpi(label: 'analytics.pending-orders', value: p.pendingOrders),
      DashboardKpi(label: 'analytics.total-orders', value: p.totalOrders),
      DashboardKpi(
        label: 'analytics.confirmed-orders',
        value: p.confirmedOrders,
      ),
      DashboardKpi(
        label: 'analytics.cancelled-orders',
        value: p.cancelledOrders,
      ),
    ];
  }

  List<SalesTrendPoint> get trend {
    final p = _provider;
    return p == null || isBuyer
        ? const []
        : groupSalesTrend(p.salesTrend, _granularity, _monthStart, _today);
  }

  bool get hasSales => trend.any((point) => point.litres > 0);

  List<(String status, int count)> get statusCounts => [
    for (final status in OrderStatus.values)
      (status, _orders.where((o) => o.status == status).length),
  ];

  List<Order> get recentOrders =>
      ([..._orders]..sort((a, b) => b.id.compareTo(a.id))).take(5).toList();

  void setGranularity(String value) {
    _granularity = value;
    notifyListeners();
  }

  Future<void> refresh() async {
    await Future.wait([
      load(),
      if (!isBuyer) ...[loadCriticalTanks(), loadTodayDeliveries()],
    ]);
  }

  Future<void> load() async {
    final id = isBuyer ? _iam.companyId : _iam.providerId;
    _error = false;
    if (id == null) {
      _loading = false;
      _error = true;
      notifyListeners();
      return;
    }
    _loading = true;
    _buyer = null;
    _provider = null;
    final seq = ++_analyticsSeq;
    notifyListeners();
    try {
      if (isBuyer) {
        final data = await _analytics.getBuyerAnalytics(id);
        if (seq == _analyticsSeq) _buyer = data;
      } else {
        final data = await _analytics.getProviderAnalytics(
          id,
          _monthStart,
          _today,
        );
        if (seq == _analyticsSeq) _provider = data;
      }
    } catch (_) {
      if (seq == _analyticsSeq) _error = true;
    }
    if (seq == _analyticsSeq) _loading = false;
    notifyListeners();
    await Future.wait([loadOrders(), if (!isBuyer) loadInbox()]);
  }

  Future<void> loadOrders() async {
    final id = isBuyer ? _iam.companyId : _iam.providerId;
    final seq = ++_ordersSeq;
    _ordersLoading = true;
    _ordersError = false;
    _orders = [];
    notifyListeners();
    if (id == null || id == 0) {
      _ordersLoading = false;
      _ordersError = true;
      notifyListeners();
      return;
    }
    try {
      final rows = await _ordering.orders(isBuyer ? 'company' : 'provider', id);
      if (seq == _ordersSeq) _orders = rows;
    } catch (_) {
      if (seq == _ordersSeq) _ordersError = true;
    }
    if (seq == _ordersSeq) _ordersLoading = false;
    notifyListeners();
  }

  Future<void> loadInbox() async {
    if (isBuyer) return;
    final seq = ++_inboxSeq;
    _pendingRequests = [];
    _inboxLoading = true;
    _inboxError = false;
    notifyListeners();
    try {
      final rows = await _ordering.requestInbox();
      if (seq == _inboxSeq) {
        _pendingRequests = [
          for (final r in rows)
            if (r.status == RequestStatus.pending) r,
        ];
      }
    } catch (_) {
      if (seq == _inboxSeq) _inboxError = true;
    }
    if (seq == _inboxSeq) _inboxLoading = false;
    notifyListeners();
  }

  Future<void> loadCriticalTanks() async {
    _criticalTanks = const CardState();
    notifyListeners();
    try {
      final rows = await _equipment.tanks();
      final critical = [
        for (final t in rows)
          if (t.critical) t,
      ]..sort((a, b) => a.levelPercent.compareTo(b.levelPercent));
      _criticalTanks = CardState(
        loading: false,
        data: critical.take(_criticalLimit).toList(),
      );
    } catch (_) {
      _criticalTanks = const CardState(loading: false, error: true);
    }
    notifyListeners();
  }

  Future<void> loadTodayDeliveries() async {
    _todayDeliveries = const CardState();
    notifyListeners();
    try {
      _todayDeliveries = CardState(
        loading: false,
        data: await _fulfillment.deliveries(_today),
      );
    } catch (_) {
      _todayDeliveries = const CardState(loading: false, error: true);
    }
    notifyListeners();
  }
}

/// Hoy en America/Lima (UTC-5, sin horario de verano) como `yyyy-MM-dd`.
String _limaToday() {
  final lima = DateTime.now().toUtc().subtract(const Duration(hours: 5));
  return '${lima.year}-${_two(lima.month)}-${_two(lima.day)}';
}

String _two(int n) => n.toString().padLeft(2, '0');
