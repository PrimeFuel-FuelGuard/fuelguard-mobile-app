/// Resumen del panel: combustible total y órdenes pendientes.
class DashboardSummary {
  const DashboardSummary({
    required this.totalFuel,
    required this.pendingOrders,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      DashboardSummary(
        totalFuel: (json['totalFuel'] as num).toDouble(),
        pendingOrders: (json['pendingOrders'] as num).toInt(),
      );

  final double totalFuel;
  final int pendingOrders;

  Map<String, dynamic> toJson() => {
    'totalFuel': totalFuel,
    'pendingOrders': pendingOrders,
  };

  DashboardSummary copyWith({double? totalFuel, int? pendingOrders}) =>
      DashboardSummary(
        totalFuel: totalFuel ?? this.totalFuel,
        pendingOrders: pendingOrders ?? this.pendingOrders,
      );
}
