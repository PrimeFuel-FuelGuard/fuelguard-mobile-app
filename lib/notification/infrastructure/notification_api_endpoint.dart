import '../../environments/environment.dart';
import '../../iam/infrastructure/auth_interceptor.dart';
import '../../shared/infrastructure/error_handling_enabled_base_type.dart';
import '../domain/model/notification_entity.dart';
import 'notification_assembler.dart';
import 'notification_response.dart';

const String _endpointUrl = '${Environment.serverBasePath}/me/notifications';

class NotificationApiEndpoint extends ErrorHandlingEnabledBaseType {
  NotificationApiEndpoint(this._http);

  final AppHttpClient _http;
  final String endpointUrl = _endpointUrl;
  final NotificationAssembler _assembler = NotificationAssembler();

  Notification _one(dynamic json) => _assembler.toEntity(
    NotificationResource.fromJson(json as Map<String, dynamic>),
  );

  Future<List<Notification>> getNotifications() async => [
    for (final e in (await execute(() => _http.getJson(endpointUrl)) as List))
      _one(e),
  ];

  Future<List<Notification>> getUnreadNotifications() async => [
    for (final e
        in (await execute(() => _http.getJson('$endpointUrl/unread')) as List))
      _one(e),
  ];

  Future<Notification> markAsRead(int id) async =>
      _one(await execute(() => _http.postJson('$endpointUrl/$id/read', {})));
}
