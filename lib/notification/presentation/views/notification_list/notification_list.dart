import 'package:material_ui/material_ui.dart' hide Notification;

import '../../../../app_config.dart';
import '../../../../iam/application/iam_store.dart';
import '../../../../iam/domain/model/session_entity.dart';
import '../../../../shared/infrastructure/format.dart';
import '../../../../shared/infrastructure/i18n/translate_service.dart';
import '../../../../shared/infrastructure/navigation.dart';
import '../../../../shared/presentation/component/empty_state/empty_state.dart';
import '../../../../shared/presentation/component/error_banner/error_banner.dart';
import '../../../../shared/presentation/component/loading_view/loading_view.dart';
import '../../../../shared/presentation/component/status_chip/status_chip.dart';
import '../../../application/notification_store.dart';
import '../../../domain/model/notification_entity.dart';

/// Bandeja de notificaciones: filtro todas/no leídas, marcar como leída al tocar y marcar todas.
class NotificationList extends StatefulWidget {
  const NotificationList({super.key});

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  late final NotificationStore _store;
  late final IamStore _iam;
  bool _ready = false;
  bool _unreadOnly = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final app = AppScope.of(context);
    _store = app.notificationStore;
    _iam = app.iamStore;
    _store.addListener(_onStoreChange);
    _store.loadNotifications();
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChange);
    super.dispose();
  }

  void _onStoreChange() {
    final message = _store.successMsg;
    if (message.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.tr(message))));
    _store.clearMessages();
  }

  Future<void> _reload() => _unreadOnly
      ? _store.loadUnreadNotifications()
      : _store.loadNotifications();

  void _setUnreadOnly(bool value) {
    setState(() => _unreadOnly = value);
    _reload();
  }

  String? _linkFor(Notification n) {
    if (n.type == NotificationType.orderAccepted ||
        n.type == NotificationType.orderRejected ||
        n.isRequestEvent()) {
      return '/ordering/request-list';
    }
    if (n.isDeliveryEvent() &&
        n.referenceId != null &&
        _iam.role == UserRole.provider) {
      return '/fulfillment/delivery-detail/${n.referenceId}';
    }
    return null;
  }

  void _open(Notification n) {
    if (!n.read) _store.markAsRead(n.id);
    final link = _linkFor(n);
    if (link != null) context.push(link);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) => Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilterChip(
                label: Text(context.tr('notification-list.show-all')),
                selected: !_unreadOnly,
                onSelected: (_) => _setUnreadOnly(false),
              ),
              FilterChip(
                label: Text(context.tr('notification-list.show-unread')),
                selected: _unreadOnly,
                onSelected: (_) => _setUnreadOnly(true),
              ),
              FilledButton.icon(
                onPressed: _store.isLoading || _store.unreadCount == 0
                    ? null
                    : _store.markAllAsRead,
                icon: const Icon(Icons.done_all),
                label: Text(context.tr('notification-list.mark-all-read')),
              ),
            ],
          ),
        ),
        if (_store.error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ErrorBanner(message: _store.error),
          ),
        Expanded(
          child: RefreshIndicator(onRefresh: _reload, child: _list(context)),
        ),
      ],
    ),
  );

  Widget _list(BuildContext context) {
    final items = _store.notificationList;
    if (items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_store.isLoading)
            const LoadingView()
          else
            EmptyState(
              message: context.tr('notification-list.empty'),
              icon: Icons.notifications_off_outlined,
            ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: items.length,
      itemBuilder: (context, i) => _NotificationCard(
        notification: items[i],
        onTap: () => _open(items[i]),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final Notification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final scheme = Theme.of(context).colorScheme;
    final reference = _referenceKey(n);
    return Card(
      color: n.read ? null : scheme.primaryContainer.withValues(alpha: 0.35),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: scheme.secondaryContainer,
          child: Icon(_iconFor(n), color: scheme.onSecondaryContainer),
        ),
        title: Text(
          n.title,
          style: TextStyle(
            fontWeight: n.read ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(n.message),
            if (reference != null && n.referenceId != null)
              Text('${context.tr(reference)}: #${n.referenceId}'),
            Text(
              formatDateTime(n.createdAt),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        trailing: StatusChip(
          label: context.tr('notification-type.${n.type.toLowerCase()}'),
          tone: n.read ? StatusTone.neutral : StatusTone.pending,
        ),
      ),
    );
  }
}

String? _referenceKey(Notification n) {
  if (n.type == NotificationType.orderAccepted ||
      n.type == NotificationType.orderRejected ||
      n.isRequestEvent()) {
    return 'notification-list.fields.request';
  }
  if (n.isDeliveryEvent()) return 'notification-list.fields.delivery';
  return null;
}

IconData _iconFor(Notification n) {
  if (n.isRequestEvent()) return Icons.assignment;
  if (n.isPaymentEvent()) return Icons.payments;
  if (n.isOrderEvent()) return Icons.receipt_long;
  if (n.isDeliveryEvent()) return Icons.local_shipping;
  return Icons.notifications;
}
