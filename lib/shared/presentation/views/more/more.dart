import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../infrastructure/i18n/translate_service.dart';
import '../../../infrastructure/navigation.dart';
import '../../component/layout/layout.dart';

/// Pantalla "Más" (`/more`): secciones restantes según el rol, como ListTiles.
class More extends StatelessWidget {
  const More({super.key});

  @override
  Widget build(BuildContext context) {
    final iam = AppScope.of(context).iamStore;
    return ListenableBuilder(
      listenable: iam,
      builder: (context, _) {
        final options = moreNavOptions(iam);
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: options.length,
          separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, i) {
            final o = options[i];
            return ListTile(
              leading: Icon(
                o.icon,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(context.tr(o.label)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(o.link),
            );
          },
        );
      },
    );
  }
}
