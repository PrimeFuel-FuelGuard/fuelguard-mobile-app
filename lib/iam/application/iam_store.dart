import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../environments/environment.dart';
import '../../shared/infrastructure/demo/demo_world.dart';
import '../domain/model/session_entity.dart';
import '../infrastructure/iam_api.dart';

const _storageKey = 'fuelguard.session';
const _organizationKey = 'fuelguard.organization';
const _demoKey = 'fuelguard.demo';

/// Estado de sesión (equivale a `IamStore`). La sesión se restaura de forma síncrona desde
/// `SharedPreferences` (ya cargadas antes de `runApp`).
class IamStore extends ChangeNotifier {
  IamStore(this._api, this._prefs) {
    _current = _restoreSession();
    _selectedOrganization = _restoreOrganization();
  }

  final IamApi _api;
  final SharedPreferences _prefs;

  /// Lo asigna `App`: navega (descartando la pila) a la URL indicada tras un logout.
  void Function(String url)? navigate;

  /// Solo memoria: nunca persistir el token de una invitación en la sesión.
  String pendingInvitationToken = '';

  Session? _current;
  int? _selectedOrganization;

  int? get organizationId => _selectedOrganization;
  Session? get session => _current;
  String? get role => sessionRole(_current);
  bool get isAuthenticated => _current?.token.isNotEmpty ?? false;
  bool get isBuyer => role == UserRole.buyer;
  bool get isProvider => role == UserRole.provider;
  bool get isAdmin => _current?.roles.contains('ROLE_ADMIN') ?? false;
  int? get userId => _current?.id;
  int? get companyId => _current?.companyId;
  int? get providerId => _current?.providerId;

  Session? _restoreSession() {
    try {
      final raw =
          _prefs.getString(_storageKey) ?? _prefs.getString('fulltank.session');
      if (raw == null) return null;
      final session = Session.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return session.token.isNotEmpty ? session : null;
    } catch (_) {
      return null;
    }
  }

  int? _restoreOrganization() {
    final session = _current;
    try {
      final raw = _prefs.getString(_organizationKey);
      if (raw != null) {
        final saved = jsonDecode(raw) as Map<String, dynamic>;
        final id = (saved['organizationId'] as num?)?.toInt();
        if (saved['userId'] == session?.id &&
            session!.memberships.any((m) => m.organizationId == id)) {
          return id;
        }
      }
    } catch (_) {
      /* Descartar un contexto local inválido. */
    }
    _prefs.remove(_organizationKey);
    return session?.memberships.isNotEmpty == true
        ? session!.memberships.first.organizationId
        : null;
  }

  Future<Session> signIn(String username, String password) async {
    final session = await _api.signIn(username, password);
    _save(session);
    return session;
  }

  Future<Session> signUp(SignUpForm form) async {
    await _api.signUp(form);
    return signIn(form.username, form.password);
  }

  /// Entra en modo demo (bypass) con un perfil de [role] (`BUYER`, `PROVIDER` o `ADMIN`).
  Future<Session> bypass(String role) async {
    Environment.demoMode = true;
    await _prefs.setBool(_demoKey, true);
    final session = DemoWorld.sessionFor(role);
    _save(session);
    return session;
  }

  /// Recarga las membresías; conserva el orden previo (no cambia la organización activa).
  Future<List<OrganizationProfile>> refreshMemberships() async {
    final requested = _current;
    final organizations = await _api.getOrganizations();
    final session = _current;
    if (requested == null ||
        session == null ||
        session.token != requested.token ||
        session.id != requested.id) {
      return organizations;
    }
    final previousIds = [for (final m in session.memberships) m.organizationId];
    final memberships = [
      for (final o in organizations)
        Membership(organizationId: o.id, role: o.role),
    ];
    int index(Membership m) {
      final i = previousIds.indexOf(m.organizationId);
      return i < 0 ? previousIds.length : i;
    }

    memberships.sort((a, b) => index(a) - index(b));
    _save(session.copyWith(memberships: memberships));
    return organizations;
  }

  /// Limpia sesión y preferencias, y navega a `/login` (con `returnUrl` y token de invitación opcionales).
  void logout({String? returnUrl, String? invitationToken}) {
    pendingInvitationToken = invitationToken ?? '';
    _current = null;
    _selectedOrganization = null;
    Environment.demoMode = false;
    _prefs.remove(_storageKey);
    _prefs.remove(_organizationKey);
    _prefs.remove(_demoKey);
    notifyListeners();
    navigate?.call(
      returnUrl != null
          ? '/login?returnUrl=${Uri.encodeQueryComponent(returnUrl)}'
          : '/login',
    );
  }

  bool selectOrganization(int? organizationId) {
    final session = _current;
    if (session == null ||
        (organizationId != null &&
            !session.memberships.any(
              (m) => m.organizationId == organizationId,
            ))) {
      return false;
    }
    _selectedOrganization = organizationId;
    if (organizationId == null) {
      _prefs.remove(_organizationKey);
    } else {
      _prefs.setString(
        _organizationKey,
        jsonEncode({'userId': session.id, 'organizationId': organizationId}),
      );
    }
    notifyListeners();
    return true;
  }

  void _save(Session session) {
    final previousUserId = _current?.id;
    _current = session;
    _prefs.setString(_storageKey, jsonEncode(session.toJson()));
    final selected = previousUserId == session.id
        ? _selectedOrganization
        : null;
    final first = session.memberships.isNotEmpty
        ? session.memberships.first.organizationId
        : null;
    if (!selectOrganization(
      session.memberships.any((m) => m.organizationId == selected)
          ? selected
          : first,
    )) {
      _selectedOrganization = null;
    }
    notifyListeners();
  }

  // Casos de uso de perfil, organización y contraseña: las vistas no llaman a la infraestructura.
  Future<UserProfile> getUser(int userId) => _api.getUser(userId);
  Future<BuyerCompanyProfile> getBuyerCompany(int id) =>
      _api.getBuyerCompany(id);
  Future<ProviderCompanyProfile> getProviderCompany(int id) =>
      _api.getProviderCompany(id);
  Future<BuyerCompanyProfile> updateBuyerCompany(
    int id,
    BuyerCompanyProfile p,
  ) => _api.updateBuyerCompany(id, p);
  Future<ProviderCompanyProfile> updateProviderCompany(
    int id,
    ProviderCompanyProfile p,
  ) => _api.updateProviderCompany(id, p);
  Future<OrganizationProfile> onboardOrganization(
    String name,
    String ruc,
    String type,
  ) => _api.onboardOrganization(name, ruc, type);
  Future<OrganizationInvitation> inviteMember(
    int organizationId,
    String email,
    String role,
  ) => _api.inviteMember(organizationId, email, role);
  Future<OrganizationInvitation> revokeInvitation(int invitationId) =>
      _api.revokeInvitation(invitationId);
  Future<void> requestPasswordReset(String email) =>
      _api.requestPasswordReset(email);
  Future<void> confirmPasswordReset(String token, String newPassword) =>
      _api.confirmPasswordReset(token, newPassword);
}
