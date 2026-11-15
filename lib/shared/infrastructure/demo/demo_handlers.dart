import '../../../admin/infrastructure/demo/admin_demo_handler.dart';
import '../../../analytics/infrastructure/demo/analytics_demo_handler.dart';
import '../../../dashboard/infrastructure/demo/dashboard_demo_handler.dart';
import '../../../equipment/infrastructure/demo/equipment_demo_handler.dart';
import '../../../fulfillment/infrastructure/demo/fulfillment_demo_handler.dart';
import '../../../iam/infrastructure/demo/iam_demo_handler.dart';
import '../../../inventory/infrastructure/demo/inventory_demo_handler.dart';
import '../../../notification/infrastructure/demo/notification_demo_handler.dart';
import '../../../ordering/infrastructure/demo/ordering_demo_handler.dart';
import 'demo_handler.dart';

/// Registro de manejadores demo (se consultan en orden; el primero que responda gana).
final List<DemoHandler> demoHandlers = [
  IamDemoHandler(),
  AdminDemoHandler(),
  AnalyticsDemoHandler(),
  DashboardDemoHandler(),
  EquipmentDemoHandler(),
  FulfillmentDemoHandler(),
  InventoryDemoHandler(),
  NotificationDemoHandler(),
  OrderingDemoHandler(),
];
