// Formato de números, dinero y fechas (sin `intl`).

String formatNumber(num value, [int decimals = 0]) {
  final fixed = value.toStringAsFixed(decimals);
  final negative = fixed.startsWith('-');
  final unsigned = negative ? fixed.substring(1) : fixed;
  final parts = unsigned.split('.');
  final grouped = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${negative ? '-' : ''}$grouped${parts.length > 1 ? '.${parts[1]}' : ''}';
}

/// `S/ 1,234.50`
String formatMoney(num value, {String currency = 'S/'}) =>
    '$currency ${formatNumber(value, 2)}';

DateTime? _parse(Object? value) {
  if (value is DateTime) return value.toLocal();
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toLocal();
  }
  return null;
}

String _two(int n) => n.toString().padLeft(2, '0');

/// `dd/MM/yyyy` (o `—` si no hay fecha).
String formatDate(Object? value) {
  final d = _parse(value);
  return d == null ? '—' : '${_two(d.day)}/${_two(d.month)}/${d.year}';
}

/// `dd/MM/yyyy HH:mm` (o `—` si no hay fecha).
String formatDateTime(Object? value) {
  final d = _parse(value);
  return d == null ? '—' : '${formatDate(d)} ${_two(d.hour)}:${_two(d.minute)}';
}
