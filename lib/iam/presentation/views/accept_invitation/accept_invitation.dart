import 'package:material_ui/material_ui.dart';

import '../../../../app_config.dart';
import '../../../../shared/infrastructure/error_handling_enabled_base_type.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/infrastructure/navigation.dart';
import '../../../../shared/presentation/component/language_switcher/language_switcher.dart';
import '../../../../shared/presentation/theme/app_theme.dart';
import '../../../infrastructure/iam_api.dart';
import '../iam_card.dart';

/// Aceptar invitación (`/accept-invitation` y `/accept-invitation/:token`).
class AcceptInvitation extends StatefulWidget {
  const AcceptInvitation({super.key, this.routeToken});

  final String? routeToken;

  @override
  State<AcceptInvitation> createState() => _AcceptInvitationState();
}

class _AcceptInvitationState extends State<AcceptInvitation> {
  static const _returnUrl = '/accept-invitation';
  final _token = TextEditingController();
  bool _initialized = false;
  int _generation = 0; // invalida respuestas de una invitación anterior
  bool _sending = false;
  String _error = '';
  OrganizationInvitation? _accepted;
  bool _refreshing = false;
  bool _refreshError = false;
  OrganizationProfile? _organization;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final iam = AppScope.of(context).iamStore;
    final routeToken = widget.routeToken;
    if (routeToken != null && routeToken.isNotEmpty) {
      iam.pendingInvitationToken = routeToken;
      _token.text = routeToken;
      // Se quita el token de la URL.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.replace(_returnUrl);
      });
    } else {
      _token.text = iam.pendingInvitationToken;
    }
  }

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  void _changeAccount() {
    AppScope.of(context).iamStore
        .logout(returnUrl: _returnUrl, invitationToken: _token.text.trim());
  }

  void _changeToken(String value) {
    if (_sending) return;
    AppScope.of(context).iamStore.pendingInvitationToken = value;
    setState(() => _error = '');
  }

  Future<void> _accept() async {
    final config = AppScope.of(context);
    if (!config.iamStore.isAuthenticated ||
        _sending ||
        _accepted != null ||
        _token.text.trim().isEmpty) {
      return;
    }
    final generation = ++_generation;
    setState(() {
      _error = '';
      _sending = true;
    });
    try {
      final invitation = await IamApi(config.httpClient)
          .acceptInvitation(_token.text.trim());
      if (!mounted || generation != _generation) return;
      _token.clear();
      config.iamStore.pendingInvitationToken = '';
      setState(() {
        _accepted = invitation.copyWith(token: '');
        _sending = false;
      });
      _refreshOrganizations();
    } catch (e) {
      if (!mounted || generation != _generation) return;
      final key = e is ApiException ? e.message : 'errors.generic';
      setState(() {
        _error =
            const [
              '400',
              '401',
              '403',
              '404',
              '409',
              '422',
            ].any((s) => key == 'errors.http-$s')
            ? key.replaceFirst('errors.', 'accept-invitation.')
            : key;
        _sending = false;
      });
    }
  }

  Future<void> _refreshOrganizations() async {
    final accepted = _accepted;
    if (accepted == null || _refreshing) return;
    final generation = _generation;
    setState(() {
      _refreshing = true;
      _refreshError = false;
    });
    try {
      final organizations = await AppScope.of(context).iamStore
          .refreshMemberships();
      if (!mounted || generation != _generation) return;
      setState(() {
        _organization = organizations
            .where((o) => o.id == accepted.organizationId)
            .firstOrNull;
        _refreshing = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _refreshError = true;
          _refreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final iam = AppScope.of(context).iamStore;
    final accepted = _accepted;
    return IamCard(
      title: context.tr('accept-invitation.title'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          const Align(
            alignment: Alignment.centerRight,
            child: LanguageSwitcher(),
          ),
          if (accepted != null) ...[
            Text(
              context.tr('accept-invitation.accepted'),
              style: const TextStyle(
                color: FgColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_refreshing) Text(context.tr('accept-invitation.refreshing')),
            if (_refreshError) ...[
              IamErrorText(context.tr('accept-invitation.refresh-error')),
              OutlinedButton(
                onPressed: _refreshing ? null : _refreshOrganizations,
                child: Text(context.tr('accept-invitation.retry-refresh')),
              ),
            ],
            if (_organization != null)
              Text(
                '${_organization!.name} · ${context.tr('invitations.role-${accepted.role.toLowerCase()}')}',
              ),
            TextButton(
              onPressed: () => context.go('/profile?tab=organizations'),
              child: Text(context.tr('accept-invitation.view-organizations')),
            ),
          ] else ...[
            Text(
              context.tr('accept-invitation.help'),
              style: const TextStyle(color: Color(0xFF4B5563)),
            ),
            TextField(
              controller: _token,
              obscureText: true,
              enabled: !_sending,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: _changeToken,
              decoration: InputDecoration(
                labelText: context.tr('invitations.token'),
              ),
            ),
            if (iam.isAuthenticated) ...[
              Text(
                context.tr('accept-invitation.account', {
                  'email': iam.session?.username,
                }),
                style: const TextStyle(color: FgColors.primary),
              ),
              Text(
                context.tr('accept-invitation.account-warning'),
                style: const TextStyle(color: Color(0xFF4B5563)),
              ),
              ListenableBuilder(
                listenable: _token,
                builder: (context, _) => FilledButton(
                  onPressed: _token.text.trim().isEmpty || _sending
                      ? null
                      : _accept,
                  child: Text(
                    context.tr(
                      _sending
                          ? 'accept-invitation.accepting'
                          : 'accept-invitation.accept',
                    ),
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: _sending ? null : _changeAccount,
                child: Text(context.tr('accept-invitation.change-account')),
              ),
            ] else ...[
              Text(
                context.tr('accept-invitation.sign-in-required'),
                style: const TextStyle(color: FgColors.primary),
              ),
              TextButton(
                onPressed: () => context.push(
                  '/login?returnUrl=${Uri.encodeQueryComponent(_returnUrl)}',
                ),
                child: Text(context.tr('auth.login.link')),
              ),
              TextButton(
                onPressed: () => context.push(
                  '/register/buyer?returnUrl=${Uri.encodeQueryComponent(_returnUrl)}',
                ),
                child: Text(context.tr('auth.register.buyer-link')),
              ),
              TextButton(
                onPressed: () => context.push(
                  '/register/distributor?returnUrl=${Uri.encodeQueryComponent(_returnUrl)}',
                ),
                child: Text(context.tr('auth.register.provider-link')),
              ),
            ],
            if (_error.isNotEmpty) ...[
              IamErrorText(context.tr(_error)),
              if (_error == 'accept-invitation.http-401')
                TextButton(
                  onPressed: () => context.push(
                    '/login?returnUrl=${Uri.encodeQueryComponent(_returnUrl)}',
                  ),
                  child: Text(context.tr('auth.login.link')),
                ),
            ],
          ],
        ],
      ),
    );
  }
}
