import 'package:material_ui/material_ui.dart';

import '../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../shared/presentation/theme/app_theme.dart';

/// Pantalla móvil común de las vistas de autenticación: scroll a pantalla completa, 16 dp de margen.
///
/// Con [brand] muestra la cabecera de marca (logo + FuelGuard) en vez de la AppBar.
class IamCard extends StatelessWidget {
  const IamCard({
    super.key,
    required this.child,
    this.title,
    this.brand = false,
    this.showBackButton = true,
    this.maxWidth = 560,
  });

  final Widget child;
  final String? title;
  final bool brand;
  final bool showBackButton;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: brand
        ? null
        : AppBar(
            title: Text(title ?? 'FuelGuard'),
            automaticallyImplyLeading: showBackButton,
            backgroundColor: FgColors.bg,
            foregroundColor: FgColors.text,
            scrolledUnderElevation: 0,
          ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: child,
          ),
        ),
      ),
    ),
  );
}

/// Encabezado de sección dentro de un formulario móvil.
class IamSectionTitle extends StatelessWidget {
  const IamSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(color: FgColors.primary, fontWeight: FontWeight.w600),
    ),
  );
}

/// Mensaje de error de formulario.
class IamErrorText extends StatelessWidget {
  const IamErrorText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: TextStyle(color: Theme.of(context).colorScheme.error));
}

/// Campo de contraseña con botón mostrar/ocultar.
class PasswordField extends StatelessWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.visible,
    required this.onToggle,
    this.validator,
    this.onChanged,
    this.helper,
    this.maxLength,
    this.autofillHints = const [AutofillHints.password],
  });

  final TextEditingController controller;
  final String label;
  final bool visible;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final String? helper;
  final int? maxLength;
  final Iterable<String> autofillHints;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: !visible,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    validator: validator,
    onChanged: onChanged,
    maxLength: maxLength,
    autofillHints: autofillHints,
    decoration: InputDecoration(
      labelText: label,
      helperText: helper,
      helperMaxLines: 3,
      errorMaxLines: 3,
      counterText: '',
      suffixIcon: IconButton(
        tooltip: context.tr(
          visible ? 'auth.hide-password' : 'auth.show-password',
        ),
        icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
        onPressed: onToggle,
      ),
    ),
  );
}

/// Validaciones compartidas de IAM (mismas reglas y claves que Angular).
abstract final class IamValidators {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+$');

  static String? email(BuildContext context, String? v) {
    final value = v ?? '';
    if (value.isEmpty) return context.tr('auth.validation.email-required');
    if (value.length > 100) return context.tr('auth.validation.email-length');
    if (!_email.hasMatch(value)) {
      return context.tr('auth.validation.email-invalid');
    }
    return null;
  }

  static bool blank(String? v) => (v ?? '').trim().isEmpty;
}
