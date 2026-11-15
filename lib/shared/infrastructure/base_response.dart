/// Recurso mínimo del API: todo recurso lleva un id numérico.
abstract class BaseResource {
  int get id;
  Map<String, dynamic> toJson();
}

/// Envoltorio de respuesta paginada/anidada del backend.
abstract class BaseResponse {}
