import 'model/analytics_entity.dart';

/// Granularidad de la tendencia: día, semana o mes.
abstract final class TrendGranularity {
  static const day = 'day';
  static const week = 'week';
  static const month = 'month';
  static const values = [day, week, month];
}

const int _dayMs = 86400000;

/// `yyyy-MM-dd` → ms UTC (`null` si la fecha es inválida; en JS sería NaN y el bucle no corre).
int? _toMs(String d) =>
    DateTime.tryParse('${d}T00:00:00Z')?.millisecondsSinceEpoch;

String _toIso(int ms) => DateTime.fromMillisecondsSinceEpoch(
  ms,
  isUtc: true,
).toIso8601String().substring(0, 10);

/// Rellena los días vacíos con 0 entre from y to y agrupa por día, semana (lunes ISO) o mes (yyyy-MM).
List<SalesTrendPoint> groupSalesTrend(
  List<SalesTrendPoint> points,
  String by,
  String from,
  String to,
) {
  final byDay = <String, double>{for (final p in points) p.date: p.litres};
  final out = <String, double>{};
  final start = _toMs(from);
  final end = _toMs(to);
  if (start == null || end == null) return [];
  for (var t = start; t <= end; t += _dayMs) {
    final day = _toIso(t);
    final utcDay =
        DateTime.fromMillisecondsSinceEpoch(t, isUtc: true).weekday %
        7; // 0 = domingo (getUTCDay)
    final key = by == TrendGranularity.day
        ? day
        : by == TrendGranularity.month
        ? day.substring(0, 7)
        : _toIso(t - ((utcDay + 6) % 7) * _dayMs);
    out[key] = (out[key] ?? 0) + (byDay[day] ?? 0);
  }
  return [
    for (final e in out.entries) SalesTrendPoint(date: e.key, litres: e.value),
  ];
}
