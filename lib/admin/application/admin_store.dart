import 'package:material_ui/material_ui.dart';

import '../../ordering/infrastructure/ordering_api.dart';
import '../../shared/infrastructure/error_handling_enabled_base_type.dart';
import '../infrastructure/admin_api.dart';

/// Estado de administración: usuarios, métricas de API, pagos y evidencias (equivale a `admin.store.ts`).
class AdminStore extends ChangeNotifier {
  AdminStore(this._api);

  final AdminApi _api;
  List<AdminUser> _users = [];
  List<ApiMetric> _metrics = [];
  List<Payment> _payments = [];
  bool _loading = false;
  String? _error;
  String? _notice;

  List<AdminUser> get users => _users;
  List<ApiMetric> get metrics => _metrics;
  List<Payment> get payments => _payments;
  bool get loading => _loading;
  String? get error => _error;

  /// Clave i18n del último resultado exitoso de una acción.
  String? get notice => _notice;

  void clearNotice() {
    _notice = null;
    notifyListeners();
  }

  Future<void> loadUsers() => _run(_api.users, (value) => _users = value);

  Future<void> loadMetrics(String version) =>
      _run(() => _api.metrics(version), (value) => _metrics = value);

  Future<void> loadPayments() =>
      _run(_api.payments, (value) => _payments = value);

  Future<void> promote(AdminUser user) =>
      _run(() => _api.promote(user.id), (result) {
        _users = [
          for (final u in _users)
            u.id == result.userId ? _withRoles(u, result.roles) : u,
        ];
        _notice = 'admin.users.promoted';
      });

  Future<void> exportEvidence(
    int deliveryId,
    void Function(TransportEvidence evidence) done,
  ) => _run(() => _api.exportEvidence(deliveryId), done);

  Future<void> deleteEvidence(int deliveryId) => _run(
    () => _api.deleteEvidence(deliveryId),
    (_) => _notice = 'admin.evidence.deleted',
  );

  Future<void> _run<T>(
    Future<T> Function() request,
    void Function(T value) save,
  ) async {
    _loading = true;
    _error = null;
    _notice = null;
    notifyListeners();
    try {
      save(await request());
    } catch (e) {
      _error = _errorKey(e);
    }
    _loading = false;
    notifyListeners();
  }

  String _errorKey(Object e) {
    final body = e is ApiException ? e.body : null;
    return '${body?['message'] ?? body?['code'] ?? 'admin.error'}';
  }

  AdminUser _withRoles(AdminUser user, List<String> roles) => AdminUser(
    id: user.id,
    username: user.username,
    roles: roles,
    companyId: user.companyId,
    providerId: user.providerId,
  );
}
