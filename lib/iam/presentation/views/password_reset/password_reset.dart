import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/infrastructure/navigation.dart';
import '../../../infrastructure/auth_error.dart';
import '../iam_card.dart';

/// Recuperación (`/forgot-password`) o restablecimiento (`/reset-password?token=`) de contraseña.
class PasswordReset extends StatefulWidget {
  const PasswordReset({super.key, this.token});

  final String? token;

  @override
  State<PasswordReset> createState() => _PasswordResetState();
}

class _PasswordResetState extends State<PasswordReset> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _message = '';
  String _error = '';
  bool _sending = false;

  bool get _confirm => widget.token != null;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final iam = AppScope.of(context).iamStore;
    setState(() {
      _error = '';
      _sending = true;
    });
    try {
      if (_confirm) {
        await iam.confirmPasswordReset(widget.token ?? '', _password.text);
      } else {
        await iam.requestPasswordReset(_email.text);
      }
      if (mounted) {
        setState(
          () => _message = _confirm ? 'auth.reset.done' : 'auth.reset.sent',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = displayAuthError(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => IamCard(
    title: context.tr(_confirm ? 'auth.reset.title' : 'auth.forgot-title'),
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Icon(
            Icons.lock_reset,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          if (_confirm)
            TextFormField(
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              validator: (v) => (v ?? '').isEmpty
                  ? context.tr('validation.required')
                  : v!.length < 8
                  ? context.tr('validation.min-length', {'n': 8})
                  : null,
              decoration: InputDecoration(
                labelText: context.tr('auth.new-password'),
              ),
            )
          else
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: (v) => (v ?? '').isEmpty
                  ? context.tr('validation.required')
                  : !RegExp(r'^[^\s@]+@[^\s@]+$').hasMatch(v!)
                  ? context.tr('validation.email')
                  : null,
              decoration: InputDecoration(
                labelText: context.tr('auth.username'),
              ),
            ),
          if (_message.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                context.tr(_message),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          if (_error.isNotEmpty) IamErrorText(context.tr(_error)),
          FilledButton(
            onPressed: _sending ? null : _submit,
            child: Text(context.tr('auth.reset.submit')),
          ),
          TextButton(
            onPressed: () => context.push('/login'),
            child: Text(context.tr('auth.login.link')),
          ),
        ],
      ),
    ),
  );
}
