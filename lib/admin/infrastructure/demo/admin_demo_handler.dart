import '../../../shared/infrastructure/demo/demo_handler.dart';
import 'admin_demo_data.dart';

/// Datos demo de administración: usuarios, métricas de API, pagos y evidencias de transporte.
class AdminDemoHandler implements DemoHandler {
  final List<Map<String, dynamic>> _users = seedUsers();
  final Map<String, List<Map<String, dynamic>>> _metrics = seedMetrics();
  final List<Map<String, dynamic>> _payments = seedPayments();
  final Map<int, List<Map<String, dynamic>>> _evidence = seedEvidence();

  Map<String, dynamic>? _userById(int? id) {
    for (final u in _users) {
      if (u['id'] == id) return u;
    }
    return null;
  }

  @override
  Future<DemoResponse?> handle(DemoRequest r) async {
    if (r.match('GET', '/users') != null) {
      return DemoResponse.json(_users);
    }

    var m = r.match('POST', '/admin/users/:id/promote');
    if (m != null) {
      final user = _userById(int.tryParse(m['id']!));
      if (user == null) return DemoResponse.error(404, 'User not found');
      final roles = user['roles'] as List<String>;
      if (!roles.contains('ROLE_ADMIN')) roles.add('ROLE_ADMIN');
      return DemoResponse.json({
        'userId': user['id'],
        'username': user['username'],
        'roles': roles,
      });
    }

    if (r.match('GET', '/admin/api-metrics') != null) {
      final version = r.query['version'] ?? 'v1';
      return DemoResponse.json(_metrics[version] ?? const []);
    }

    if (r.match('GET', '/payments') != null) {
      return DemoResponse.json(_payments);
    }

    m = r.match('GET', '/admin/deliveries/:id/transport-evidence/export');
    if (m != null) {
      final id = int.tryParse(m['id']!);
      final samples = id == null ? null : _evidence[id];
      if (samples == null) {
        return DemoResponse.error(404, 'Transport evidence not found');
      }
      return DemoResponse.json({'deliveryId': id, 'samples': samples});
    }

    m = r.match('DELETE', '/admin/deliveries/:id/transport-evidence');
    if (m != null) {
      final id = int.tryParse(m['id']!);
      if (id == null || _evidence.remove(id) == null) {
        return DemoResponse.error(404, 'Transport evidence not found');
      }
      return DemoResponse.empty();
    }
    return null;
  }
}
