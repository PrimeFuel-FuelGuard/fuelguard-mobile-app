# FuelGuard Mobile App (`fuelguard-mobile-app`)

[![Flutter](https://img.shields.io/badge/Flutter-3.50-02569B.svg?style=flat&logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3-0175C2.svg?style=flat&logo=dart)](https://dart.dev/)
[![Android](https://img.shields.io/badge/Android-Material_3-3DDC84.svg?style=flat&logo=android)](https://m3.material.io/)
[![Architecture](https://img.shields.io/badge/Architecture-DDD_/_Bounded_Contexts-orange.svg?style=flat)](#estructura-del-proyecto-bounded-contexts)

## Descripción General

Aplicación móvil Android de **FuelGuard**, la plataforma B2B de monitoreo y abastecimiento de combustible. Es la versión móvil de [`fuelguard-web-app`](https://github.com/PrimeFuel-FuelGuard/fuelguard-web-app): conserva la misma arquitectura guiada por el dominio (**DDD**), los mismos bounded contexts, reglas de negocio y claves de traducción, con una interfaz nativa Android (Material 3).

Consume el backend [`fuelguard-platform`](https://github.com/PrimeFuel-FuelGuard/fuelguard-platform) (Spring Boot).

**Descarga:** el APK está en la sección [Releases](../../releases).

---

## Tecnologías

- **Flutter 3.50 / Dart 3**, Material 3.
- **Dependencias mínimas:** solo `http` y `shared_preferences`.
- **Estado:** `ChangeNotifier` + `ListenableBuilder` (equivalente a los *Signals* del front).
- **Navegación:** `Navigator` con rutas nombradas y guards por rol (mismas URLs que el front).
- **i18n:** Español e Inglés con los mismos `en.json` / `es.json` del front.

---

## Estructura del Proyecto (Bounded Contexts)

```
lib/
├── main.dart · app.dart · app_config.dart · app_routes.dart
├── environments/environment.dart      # URL del backend
├── shared/          # Kernel compartido: clases base, i18n, tema, layout, componentes, modo demo
├── iam/             # Sesión, login, registro, perfil, organizaciones, guards
├── ordering/        # Solicitudes de reabastecimiento, órdenes y pagos
├── fulfillment/     # Entregas, cisternas y conductores
├── equipment/       # Tanques del comprador y clientes del distribuidor
├── inventory/       # Catálogo de combustibles
├── notification/    # Notificaciones
├── dashboard/       # Resumen por rol
├── analytics/       # Reportes y tendencias
└── admin/           # Panel de administración
```

Cada contexto mantiene las capas del front:

| Capa | Contenido |
|---|---|
| `domain/model` | Entidades del dominio (`Order`, `Tank`, `Driver`…) |
| `application` | Stores (`ChangeNotifier`) con la lógica y validaciones de negocio |
| `infrastructure` | Clientes REST, assemblers y resources; `demo/` con datos de demostración |
| `presentation` | Rutas y vistas |

**Flujo de dependencias:** Vista → Store → Infraestructura. Las vistas no llaman a la infraestructura directamente.

---

## Roles y Navegación

| Rol | Barra inferior | En "Más" |
|---|---|---|
| Comprador | Dashboard · Tanques · Pedidos | Catálogo, órdenes, pagos, reportes, notificaciones, perfil |
| Distribuidor | Dashboard · Pedidos · Entregas | Clientes, inventario, órdenes, pagos, cisternas, conductores, reportes, notificaciones, perfil |
| Administrador | Admin · Analytics | Notificaciones, perfil |

---

## Modo Demo (bypass)

En el login, **"Modo demo (bypass)"** permite entrar como Comprador, Distribuidor o Administrador sin backend, con datos de ejemplo en memoria (las acciones como aceptar, rechazar o crear modifican esos datos). Útil para presentaciones y capturas.

---

## Ejecución

```bash
flutter pub get
flutter run                      # dispositivo o emulador Android
flutter build apk --release      # genera build/app/outputs/flutter-apk/app-release.apk
```

La URL del backend se configura en `lib/environments/environment.dart` (`serverBasePath`).

```bash
flutter analyze
flutter test
```
