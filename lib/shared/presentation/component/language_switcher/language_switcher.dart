import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../infrastructure/i18n/translate_service.dart';

/// Selector de idioma global (EN / ES).
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key, this.onDark = false});

  /// `true` sobre fondos oscuros (toolbar).
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final translate = AppScope.of(context).translateService;
    final current = translate.getCurrentLang();
    final color = onDark ? Colors.white : Theme.of(context).colorScheme.primary;
    return SegmentedButton<String>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        foregroundColor: color,
        selectedForegroundColor: onDark
            ? const Color(0xFF1E3A8A)
            : Colors.white,
        selectedBackgroundColor: onDark
            ? Colors.white
            : const Color(0xFF1E3A8A),
        side: BorderSide(color: color.withValues(alpha: 0.6)),
      ),
      segments: [
        for (final lang in TranslateService.languages)
          ButtonSegment(
            value: lang,
            label: Text(lang.toUpperCase()),
            tooltip: lang,
          ),
      ],
      selected: {current},
      onSelectionChanged: (s) => translate.use(s.first),
    );
  }
}
