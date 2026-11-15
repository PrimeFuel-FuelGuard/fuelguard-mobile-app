import 'package:material_ui/material_ui.dart';

import '../../../infrastructure/i18n/translate_service.dart';
import '../../../infrastructure/navigation.dart';

/// Vista 404. [invalidPath] es la ruta solicitada, sin `/` inicial.
class PageNotFound extends StatelessWidget {
  const PageNotFound({super.key, required this.invalidPath});

  final String invalidPath;

  /// Convierte el HTML simple de la traducción (`<strong>`) en spans.
  List<InlineSpan> _spans(String text) {
    final spans = <InlineSpan>[];
    final re = RegExp(r'<strong>(.*?)</strong>');
    var last = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      spans.add(
        TextSpan(
          text: m[1],
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 16,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: scheme.errorContainer,
                  child: Icon(
                    Icons.search_off,
                    size: 36,
                    color: scheme.onErrorContainer,
                  ),
                ),
                Text(
                  context.tr('page-not-found.title'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text.rich(
                  TextSpan(
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: scheme.onSurfaceVariant),
                    children: _spans(
                      context.tr('page-not-found.content', {
                        'invalid_path': invalidPath,
                      }),
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.go('/'),
                    child: Text(context.tr('page-not-found.go-home')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
