import 'package:material_ui/material_ui.dart' hide Notification;

import '../../iam/infrastructure/auth_interceptor.dart';
import '../../shared/infrastructure/error_handling_enabled_base_type.dart';
import '../domain/model/notification_entity.dart';
import '../infrastructure/notification_api.dart';

/// Estado de notificaciones (equivale a `notification.store.ts`); instancia raíz en AppConfig.
class NotificationStore extends ChangeNotifier {
  NotificationStore(AppHttpClient http) : _api = NotificationApi(http);

  final NotificationApi _api;

  List<Notification> _list = [];
  int _unread = 0;
  bool _loading = false;
  String _errorMessage = '';
  String _successMessage = '';

  List<Notification> get notificationList => _list;
  int get unreadCount => _unread;
  bool get isLoading => _loading;
  String get error => _errorMessage;
  String get successMsg => _successMessage;
  List<Notification> get orderNotifications =>
      _list.where((n) => n.isOrderEvent()).toList();
  List<Notification> get deliveryNotifications =>
      _list.where((n) => n.isDeliveryEvent()).toList();

  String _msg(Object e) =>
      e is ApiException && e.message.isNotEmpty ? e.message : 'errors.generic';

  void _fail(Object e) {
    _errorMessage = _msg(e);
    _loading = false;
    notifyListeners();
  }

  void _start() {
    _loading = true;
    _errorMessage = '';
    notifyListeners();
  }

  Future<void> loadNotifications() async {
    _start();
    try {
      final items = await _api.getNotifications();
      _list = items;
      _unread = items.where((i) => !i.read).length;
      _loading = false;
      notifyListeners();
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> loadUnreadNotifications() async {
    _start();
    try {
      final items = await _api.getUnreadNotifications();
      _unread = items.length;
      _list = items;
      _loading = false;
      notifyListeners();
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> refreshUnreadCount() async {
    try {
      _unread = (await _api.getUnreadNotifications()).length;
      notifyListeners();
    } catch (e) {
      _errorMessage = _msg(e);
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    _start();
    try {
      final updated = await _api.markAsRead(id);
      _list = [for (final i in _list) i.id == id ? updated : i];
      _unread = _unread > 0 ? _unread - 1 : 0;
      _loading = false;
      notifyListeners();
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> markAllAsRead() async {
    _start();
    _successMessage = '';
    try {
      await _api.markAllAsRead();
      _list = [for (final i in _list) i.copyWith(read: true)];
      _unread = 0;
      _successMessage = 'notification-list.all-read';
      _loading = false;
      notifyListeners();
    } catch (e) {
      _fail(e);
    }
  }

  void clearMessages() {
    _errorMessage = '';
    _successMessage = '';
    notifyListeners();
  }
}
