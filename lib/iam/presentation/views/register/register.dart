import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../inventory/domain/model/fuel_product_entity.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/infrastructure/navigation.dart';
import '../../../domain/model/session_entity.dart';
import '../../../infrastructure/auth_error.dart';
import '../iam_card.dart';

/// Registro de comprador o distribuidor. [role] (`BUYER` | `PROVIDER`) viene de los datos de la ruta.
class Register extends StatefulWidget {
  const Register({super.key, required this.role, this.returnUrl});

  final String role;
  final String? returnUrl;

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _ruc = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _sector = TextEditingController();
  final _description = TextEditingController();
  List<String> _fuelTypes = [FuelType.diesel];
  String _error = '';
  bool _submitting = false;
  bool _showPassword = false;
  late final String? _returnUrl;
  bool _initialized = false;

  bool get _isBuyer => widget.role == UserRole.buyer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
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
      _returnUrl = '/accept-invitation';
    } else {
      _returnUrl = returnUrl;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _username,
      _password,
      _name,
      _ruc,
      _address,
      _phone,
      _sector,
      _description,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _clear() => setState(() => _error = '');

  void _toggleFuelType(String type) => setState(() {
    _fuelTypes = _fuelTypes.contains(type)
        ? _fuelTypes.where((v) => v != type).toList()
        : [..._fuelTypes, type];
  });

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) {
      setState(() => _error = 'auth.validation.form-invalid');
      return;
    }
    if (!_isBuyer && _fuelTypes.isEmpty) {
      setState(() => _error = 'auth.fuel-types-required');
      return;
    }
    setState(() {
      _error = '';
      _submitting = true;
    });
    try {
      await AppScope.of(context).iamStore.signUp(
        SignUpForm(
          role: widget.role,
          username: _username.text,
          password: _password.text,
          name: _name.text,
          ruc: _ruc.text,
          address: _address.text,
          phone: _phone.text,
          sector: _sector.text,
          fuelTypesOffered: _fuelTypes,
          description: _description.text,
        ),
      );
      if (mounted) {
        context.go(_returnUrl?.isNotEmpty == true ? _returnUrl! : '/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = displayAuthError(e, 'sign-up');
          _submitting = false;
        });
      }
    }
  }

  Widget _field(
    TextEditingController controller,
    String labelKey, {
    String? Function(String?)? validator,
    TextInputType? keyboard,
    int? maxLength,
    String? helperKey,
    int maxLines = 1,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboard,
    maxLength: maxLength,
    maxLines: maxLines,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    onChanged: (_) => _clear(),
    validator: validator,
    decoration: InputDecoration(
      labelText: context.tr(labelKey),
      helperText: helperKey == null ? null : context.tr(helperKey),
      helperMaxLines: 3,
      errorMaxLines: 3,
      counterText: '',
    ),
  );

  @override
  Widget build(BuildContext context) {
    final returnQuery = _returnUrl?.isNotEmpty == true
        ? '?returnUrl=${Uri.encodeQueryComponent(_returnUrl!)}'
        : '';
    return IamCard(
      title: context.tr(
        _isBuyer ? 'auth.register.buyer-title' : 'auth.register.provider-title',
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            _field(
              _username,
              'auth.username',
              keyboard: TextInputType.emailAddress,
              maxLength: 100,
              helperKey: 'auth.register.email-hint',
              validator: (v) => IamValidators.email(context, v),
            ),
            PasswordField(
              controller: _password,
              label: context.tr('auth.password'),
              visible: _showPassword,
              maxLength: 120,
              helper: context.tr('auth.register.password-hint'),
              autofillHints: const [AutofillHints.newPassword],
              onToggle: () => setState(() => _showPassword = !_showPassword),
              onChanged: (_) => _clear(),
              validator: (v) {
                final value = v ?? '';
                if (value.isEmpty || IamValidators.blank(value)) {
                  return context.tr('auth.validation.password-required');
                }
                if (value.length < 8 || value.length > 120) {
                  return context.tr('auth.validation.password-length');
                }
                return null;
              },
            ),
            IamSectionTitle(context.tr('auth.company')),
            _field(
              _name,
              'auth.company',
              validator: (v) => IamValidators.blank(v)
                  ? context.tr('auth.validation.company-required')
                  : null,
            ),
            _field(
              _ruc,
              'auth.ruc',
              keyboard: TextInputType.number,
              maxLength: 11,
              helperKey: 'auth.register.ruc-hint',
              validator: (v) {
                if ((v ?? '').isEmpty) {
                  return context.tr('auth.validation.ruc-required');
                }
                if (!RegExp(r'^[0-9]{11}$').hasMatch(v!)) {
                  return context.tr('auth.validation.ruc-invalid');
                }
                return null;
              },
            ),
            _field(
              _address,
              'auth.address',
              validator: (v) => IamValidators.blank(v)
                  ? context.tr('auth.validation.address-required')
                  : null,
            ),
            _field(
              _phone,
              'auth.phone',
              keyboard: TextInputType.phone,
              validator: (v) {
                if ((v ?? '').isEmpty) {
                  return context.tr('auth.validation.phone-required');
                }
                if (!RegExp(r'^[+]?[0-9() .-]*[0-9][0-9() .-]*$')
                    .hasMatch(v!)) {
                  return context.tr('auth.validation.phone-invalid');
                }
                return null;
              },
            ),
            if (_isBuyer)
              _field(
                _sector,
                'auth.sector',
                validator: (v) => IamValidators.blank(v)
                    ? context.tr('auth.validation.sector-required')
                    : null,
              )
            else ...[
              Text(
                context.tr('auth.fuel-types'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final type in fuelTypes)
                    FilterChip(
                      label: Text(
                        context.tr('fuel-type.${type.toLowerCase()}'),
                      ),
                      selected: _fuelTypes.contains(type),
                      onSelected: (_) => _toggleFuelType(type),
                    ),
                ],
              ),
              if (_fuelTypes.isEmpty)
                IamErrorText(context.tr('auth.fuel-types-required')),
              _field(_description, 'auth.description', maxLines: 3),
            ],
            if (_error.isNotEmpty) IamErrorText(context.tr(_error)),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: Text(context.tr('auth.register.submit')),
            ),
            TextButton(
              onPressed: () => context.push('/login$returnQuery'),
              child: Text(context.tr('auth.login.link')),
            ),
          ],
        ),
      ),
    );
  }
}
