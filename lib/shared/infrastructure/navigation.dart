import 'package:material_ui/material_ui.dart';

/// Atajos de navegación sobre `Navigator` con las mismas URL que Angular.
extension AppNavigation on BuildContext {
  /// Apila [url] (se puede volver con atrás).
  Future<Object?> push(String url) => Navigator.of(this).pushNamed(url);

  /// Reemplaza la pantalla actual por [url].
  Future<Object?> replace(String url) =>
      Navigator.of(this).pushReplacementNamed(url);

  /// Va a [url] descartando toda la pila (opciones del menú lateral, login, logout).
  Future<Object?> go(String url) =>
      Navigator.of(this).pushNamedAndRemoveUntil(url, (_) => false);

  /// Vuelve a la pantalla anterior si existe.
  void back() => Navigator.of(this).maybePop();
}
