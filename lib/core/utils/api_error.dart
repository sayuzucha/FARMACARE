import 'dart:convert';

/// Extrae el mensaje de error legible de una respuesta HTTP del backend.
///
/// El backend (errorHandler.js) siempre responde los errores anidados así:
///   { "error": { "status": 404, "message": "Código inválido..." } }
///
/// pero varias pantallas hacían `jsonDecode(res.body)['message']` esperando
/// el mensaje en la raíz del JSON. Como esa clave nunca existe ahí, siempre
/// caían al mensaje genérico de respaldo — incluso cuando el backend sí
/// mandaba un mensaje específico y útil. Esta función revisa ambas formas
/// (la anidada real y la plana, por si acaso) antes de usar el respaldo.
String extractApiErrorMessage(String body, [String fallback = 'Ocurrió un error']) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map) {
      final error = decoded['error'];
      if (error is Map && error['message'] != null) {
        return error['message'].toString();
      }
      if (decoded['message'] != null) {
        return decoded['message'].toString();
      }
    }
  } catch (_) {
    // body no era JSON válido; usar el respaldo.
  }
  return fallback;
}
