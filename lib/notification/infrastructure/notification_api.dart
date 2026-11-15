import '../../iam/infrastructure/auth_interceptor.dart';
import '../../shared/infrastructure/error_handling_enabled_base_type.dart';
import '../domain/model/notification_entity.dart';
import 'notification_api_endpoint.dart';

class NotificationApi extends ErrorHandlingEnabledBaseType {
  NotificationApi(AppHttpClient http)
    : _endpoint = NotificationApiEndpoint(http);

  final NotificationApiEndpoint _endpoint;

  Future<List<Notification>> getNotifications() => _endpoint.getNotifications();
  Future<List<Notification>> getUnreadNotifications() =>
      _endpoint.getUnreadNotifications();
  Future<Notification> markAsRead(int id) => _endpoint.markAsRead(id);

  /// N llamadas (una por no leída); agregar un endpoint masivo solo si el volumen lo justifica.
  Future<List<Notification>> markAllAsRead() async {
    final unread = await getUnreadNotifications();
    return unread.isEmpty
        ? <Notification>[]
        : Future.wait([for (final n in unread) markAsRead(n.id)]);
  }
}
