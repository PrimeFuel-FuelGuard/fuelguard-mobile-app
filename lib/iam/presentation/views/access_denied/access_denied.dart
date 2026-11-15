import 'package:material_ui/material_ui.dart';

import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/infrastructure/navigation.dart';
import '../iam_card.dart';

/// Acceso denegado (`/access-denied`).
class AccessDenied extends StatelessWidget {
  const AccessDenied({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IamCard(
      showBackButton: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          const SizedBox(height: 32),
          Center(
            child: CircleAvatar(
              radius: 36,
              backgroundColor: scheme.errorContainer,
              child: Icon(
                Icons.lock_outline,
                size: 36,
                color: scheme.onErrorContainer,
              ),
            ),
          ),
          Text(
            context.tr('auth.denied.title'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            context.tr('auth.denied.message'),
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => context.go('/login'),
            child: Text(context.tr('auth.login.link')),
          ),
        ],
      ),
    );
  }
}
