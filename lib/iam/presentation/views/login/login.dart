import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/infrastructure/navigation.dart';
import '../../../../shared/presentation/component/language_switcher/language_switcher.dart';
import '../../../../shared/presentation/theme/app_theme.dart';
import '../../../domain/model/session_entity.dart';
import '../../../infrastructure/auth_error.dart';
import '../iam_card.dart';

/// Inicio de sesión (`/login`). [returnUrl] viene del query `returnUrl`.
class Login extends StatefulWidget {
  const Login({super.key, this.returnUrl});

  final String? returnUrl;

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  String _error = '';
  bool _sending = false;
  bool _showPassword = false;
  late final String? _returnUrl;
  late final bool _sessionRequired;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _sessionRequired = (widget.returnUrl ?? '').isNotEmpty;
    _returnUrl = _cleanInvitationReturnUrl();
  }

  /// Una URL antigua `/accept-invitation/<token>` se convierte en token en memoria.
  String? _cleanInvitationReturnUrl() {
    final returnUrl = widget.returnUrl;
    final legacy = returnUrl == null
        ? null
        : RegExp(r'^/accept-invitation/([^?#]+)$').firstMatch(returnUrl)?[1];
    if (legacy != null) {
      final iam = AppScope.of(context).iamStore;
      try {
        iam.pendingInvitationToken = Uri.decodeComponent(legacy);
      } catch (_) {
        iam.pendingInvitationToken = '';
      }
      return '/accept-invitation';
    }
    return returnUrl;
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  String _target() => _returnUrl?.isNotEmpty == true
      ? _returnUrl!
      : (AppScope.of(context).iamStore.role == UserRole.admin
            ? '/admin'
            : '/dashboard');

  Future<void> _submit() async {
    if (_sending) return;
    if (!_formKey.currentState!.validate()) {
      setState(() => _error = 'auth.validation.form-invalid');
      return;
    }
    setState(() {
      _error = '';
      _sending = true;
    });
    try {
      await AppScope.of(context).iamStore
          .signIn(_username.text, _password.text);
      if (mounted) context.go(_target());
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = displayAuthError(e, 'sign-in');
          _sending = false;
        });
      }
    }
  }

  Future<void> _bypass() async {
    final role = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                context.tr('auth.login.bypass-choose'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.storefront),
              title: Text(context.tr('auth.login.bypass-buyer')),
              onTap: () => Navigator.of(context).pop(UserRole.buyer),
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: Text(context.tr('auth.login.bypass-provider')),
              onTap: () => Navigator.of(context).pop(UserRole.provider),
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: Text(context.tr('auth.login.bypass-admin')),
              onTap: () => Navigator.of(context).pop(UserRole.admin),
            ),
          ],
        ),
      ),
    );
    if (role == null || !mounted) return;
    await AppScope.of(context).iamStore.bypass(role);
    if (mounted) context.go(_target());
  }

  @override
  Widget build(BuildContext context) {
    final returnQuery = _sessionRequired
        ? '?returnUrl=${Uri.encodeQueryComponent(_returnUrl ?? '')}'
        : '';
    final scheme = Theme.of(context).colorScheme;
    return IamCard(
      brand: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            const Align(
              alignment: Alignment.centerRight,
              child: LanguageSwitcher(),
            ),
            Column(
              spacing: 8,
              children: [
                Image.asset('assets/images/fuelguard-logo.png', height: 72),
                const Text(
                  'FuelGuard',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: FgColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              context.tr('auth.login.title'),
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              context.tr('auth.login.subtitle'),
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            if (_sessionRequired && _error.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  context.tr('auth.login.session-required'),
                  style: TextStyle(color: scheme.onPrimaryContainer),
                ),
              ),
            TextFormField(
              controller: _username,
              keyboardType: TextInputType.emailAddress,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              autofillHints: const [AutofillHints.username],
              maxLength: 100,
              onChanged: (_) => setState(() => _error = ''),
              validator: (v) => IamValidators.email(context, v),
              decoration: InputDecoration(
                labelText: context.tr('auth.username'),
                counterText: '',
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            PasswordField(
              controller: _password,
              label: context.tr('auth.password'),
              visible: _showPassword,
              onToggle: () => setState(() => _showPassword = !_showPassword),
              onChanged: (_) => setState(() => _error = ''),
              validator: (v) => IamValidators.blank(v)
                  ? context.tr('auth.validation.password-required')
                  : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/forgot-password'),
                child: Text(context.tr('auth.forgot')),
              ),
            ),
            if (_error.isNotEmpty) IamErrorText(context.tr(_error)),
            FilledButton(
              onPressed: _sending ? null : _submit,
              child: Text(
                context.tr(
                  _sending ? 'auth.login.submitting' : 'auth.login.submit',
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _sending ? null : _bypass,
              icon: const Icon(Icons.bolt),
              label: Text(context.tr('auth.login.bypass')),
            ),
            const Divider(height: 24),
            Text(
              context.tr('auth.login.no-account'),
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () =>
                        context.push('/register/buyer$returnQuery'),
                    child: Text(
                      context.tr('auth.register.buyer-link'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () =>
                        context.push('/register/distributor$returnQuery'),
                    child: Text(
                      context.tr('auth.register.provider-link'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
