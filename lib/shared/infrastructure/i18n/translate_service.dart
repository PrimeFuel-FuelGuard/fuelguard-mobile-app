import 'dart:convert';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/services.dart' show rootBundle;
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app_config.dart';

/// Traducciones desde `assets/i18n/<lang>.json` (claves anidadas con punto, `{{param}}`, fallback `en`).
class TranslateService extends ChangeNotifier {
  TranslateService(this._prefs);

  static const languages = ['en', 'es'];
  static const _storageKey = 'fuelguard.lang';

  final SharedPreferences _prefs;
  String _lang = 'en';
  Map<String, dynamic> _current = const {};
  Map<String, dynamic> _fallback = const {};

  /// Carga el idioma guardado (o el del dispositivo) antes de `runApp`.
  Future<void> init() async {
    _fallback = await _load('en');
    final saved =
        _prefs.getString(_storageKey) ?? _prefs.getString('fulltank.lang');
    final device = PlatformDispatcher.instance.locale.languageCode;
    _lang = saved == 'en' || saved == 'es'
        ? saved!
        : (device == 'es' ? 'es' : 'en');
    _current = _lang == 'en' ? _fallback : await _load(_lang);
  }

  Future<Map<String, dynamic>> _load(String lang) async =>
      jsonDecode(await rootBundle.loadString('assets/i18n/$lang.json'))
          as Map<String, dynamic>;

  String getCurrentLang() => _lang;

  Future<void> use(String lang) async {
    if (!languages.contains(lang) || lang == _lang) return;
    _current = lang == 'en' ? _fallback : await _load(lang);
    _lang = lang;
    await _prefs.setString(_storageKey, lang);
    notifyListeners();
  }

  /// Traduce [key]; si falta devuelve la clave.
  String translate(String key, [Map<String, Object?>? params]) {
    final value = _lookup(_current, key) ?? _lookup(_fallback, key);
    if (value is! String) return key;
    if (params == null || params.isEmpty) return value;
    return value.replaceAllMapped(
      RegExp(r'\{\{\s*([\w.-]+)\s*\}\}'),
      (m) => '${params[m[1]] ?? m[0]}',
    );
  }

  Object? _lookup(Map<String, dynamic> map, String key) {
    if (map[key] != null) return map[key];
    Object? node = map;
    for (final part in key.split('.')) {
      if (node is Map<String, dynamic> && node.containsKey(part)) {
        node = node[part];
      } else {
        return null;
      }
    }
    return node;
  }
}

extension TranslateContext on BuildContext {
  /// Traduce [key]; se reconstruye al cambiar de idioma.
  String tr(String key, [Map<String, Object?>? params]) =>
      AppScope.of(this).translateService.translate(key, params);
}
