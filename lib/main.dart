import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'app_config.dart';

/// Punto de entrada (equivale a `main.ts`): restaura sesión e idioma antes de `runApp`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await AppConfig.create();
  runApp(App(config: config));
}
