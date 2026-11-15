/// Coincidencia simple de rutas por segmentos: `/ordering/order-detail/:id`.
///
/// Devuelve los parámetros (`{'id': '12'}`) o `null` si [path] no coincide con [pattern].
Map<String, String>? matchPath(String pattern, String path) {
  final p = _segments(pattern);
  final s = _segments(path);
  if (p.length != s.length) return null;
  final params = <String, String>{};
  for (var i = 0; i < p.length; i++) {
    if (p[i].startsWith(':')) {
      params[p[i].substring(1)] = Uri.decodeComponent(s[i]);
    } else if (p[i] != s[i]) {
      return null;
    }
  }
  return params;
}

/// Sustituye `:param` en [template] con [params].
String fillPath(String template, Map<String, String> params) =>
    template.replaceAllMapped(
      RegExp(r':(\w+)'),
      (m) => Uri.encodeComponent(params[m[1]] ?? ''),
    );

List<String> _segments(String path) =>
    path.split('/').where((e) => e.isNotEmpty).toList();
