import '../domain/model/notification_entity.dart';
import 'notification_response.dart';

class NotificationAssembler {
  Notification toEntity(NotificationResource resource) => Notification(
    resource.id,
    resource.userId,
    resource.type,
    resource.title,
    resource.message,
    resource.read,
    resource.referenceId,
    resource.createdAt,
  );
}
