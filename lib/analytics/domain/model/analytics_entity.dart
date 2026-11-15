List<T> _list<T>(Object? v, T Function(Map<String, dynamic>) f) => [
  for (final e in (v as List? ?? const [])) f(e as Map<String, dynamic>),
];

/// Monto agregado por mes.
class MonthlyAmount {
  const MonthlyAmount({
    required this.month,
    required this.monthIndex,
    required this.amount,
  });

  factory MonthlyAmount.fromJson(Map<String, dynamic> json) => MonthlyAmount(
    month: json['month'] as String,
    monthIndex: (json['monthIndex'] as num).toInt(),
    amount: (json['amount'] as num).toDouble(),
  );

  final String month;
  final int monthIndex;
  final double amount;

  Map<String, dynamic> toJson() => {
    'month': month,
    'monthIndex': monthIndex,
    'amount': amount,
  };
}

/// Punto de la tendencia de ventas (litros por fecha).
class SalesTrendPoint {
  const SalesTrendPoint({required this.date, required this.litres});

  factory SalesTrendPoint.fromJson(Map<String, dynamic> json) =>
      SalesTrendPoint(
        date: json['date'] as String,
        litres: (json['litres'] as num).toDouble(),
      );

  final String date;
  final double litres;

  Map<String, dynamic> toJson() => {'date': date, 'litres': litres};
}

class ProviderAnalytics {
  const ProviderAnalytics({
    required this.providerId,
    required this.totalOrders,
    required this.confirmedOrders,
    required this.cancelledOrders,
    required this.totalRevenue,
    required this.monthlyRevenue,
    required this.pendingOrders,
    required this.totalFuelSoldLitres,
    required this.salesTrend,
  });

  factory ProviderAnalytics.fromJson(Map<String, dynamic> json) =>
      ProviderAnalytics(
        providerId: (json['providerId'] as num).toInt(),
        totalOrders: (json['totalOrders'] as num).toInt(),
        confirmedOrders: (json['confirmedOrders'] as num).toInt(),
        cancelledOrders: (json['cancelledOrders'] as num).toInt(),
        totalRevenue: (json['totalRevenue'] as num).toDouble(),
        monthlyRevenue: _list(json['monthlyRevenue'], MonthlyAmount.fromJson),
        pendingOrders: (json['pendingOrders'] as num).toInt(),
        totalFuelSoldLitres: (json['totalFuelSoldLitres'] as num).toDouble(),
        salesTrend: _list(json['salesTrend'], SalesTrendPoint.fromJson),
      );

  final int providerId;
  final int totalOrders;
  final int confirmedOrders;
  final int cancelledOrders;
  final double totalRevenue;
  final List<MonthlyAmount> monthlyRevenue;
  final int pendingOrders;
  final double totalFuelSoldLitres;
  final List<SalesTrendPoint> salesTrend;

  Map<String, dynamic> toJson() => {
    'providerId': providerId,
    'totalOrders': totalOrders,
    'confirmedOrders': confirmedOrders,
    'cancelledOrders': cancelledOrders,
    'totalRevenue': totalRevenue,
    'monthlyRevenue': [for (final m in monthlyRevenue) m.toJson()],
    'pendingOrders': pendingOrders,
    'totalFuelSoldLitres': totalFuelSoldLitres,
    'salesTrend': [for (final p in salesTrend) p.toJson()],
  };
}

class PlatformSummary {
  const PlatformSummary({
    required this.totalOrders,
    required this.totalDeliveries,
    required this.totalPayments,
    required this.totalRevenue,
    required this.pendingOrders,
    required this.completedDeliveries,
  });

  factory PlatformSummary.fromJson(Map<String, dynamic> json) =>
      PlatformSummary(
        totalOrders: (json['totalOrders'] as num).toInt(),
        totalDeliveries: (json['totalDeliveries'] as num).toInt(),
        totalPayments: (json['totalPayments'] as num).toInt(),
        totalRevenue: (json['totalRevenue'] as num).toDouble(),
        pendingOrders: (json['pendingOrders'] as num).toInt(),
        completedDeliveries: (json['completedDeliveries'] as num).toInt(),
      );

  final int totalOrders;
  final int totalDeliveries;
  final int totalPayments;
  final double totalRevenue;
  final int pendingOrders;
  final int completedDeliveries;

  Map<String, dynamic> toJson() => {
    'totalOrders': totalOrders,
    'totalDeliveries': totalDeliveries,
    'totalPayments': totalPayments,
    'totalRevenue': totalRevenue,
    'pendingOrders': pendingOrders,
    'completedDeliveries': completedDeliveries,
  };
}

class BuyerAnalytics {
  const BuyerAnalytics({
    required this.totalOrders,
    required this.totalSpent,
    required this.completedPayments,
    required this.pendingPayments,
    required this.monthlySpending,
  });

  factory BuyerAnalytics.fromJson(Map<String, dynamic> json) => BuyerAnalytics(
    totalOrders: (json['totalOrders'] as num).toInt(),
    totalSpent: (json['totalSpent'] as num).toDouble(),
    completedPayments: (json['completedPayments'] as num).toInt(),
    pendingPayments: (json['pendingPayments'] as num).toInt(),
    monthlySpending: _list(json['monthlySpending'], MonthlyAmount.fromJson),
  );

  final int totalOrders;
  final double totalSpent;
  final int completedPayments;
  final int pendingPayments;
  final List<MonthlyAmount> monthlySpending;

  Map<String, dynamic> toJson() => {
    'totalOrders': totalOrders,
    'totalSpent': totalSpent,
    'completedPayments': completedPayments,
    'pendingPayments': pendingPayments,
    'monthlySpending': [for (final m in monthlySpending) m.toJson()],
  };
}
