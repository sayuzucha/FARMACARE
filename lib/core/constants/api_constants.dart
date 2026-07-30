import 'package:flutter/foundation.dart';

class ApiConstants {
  // Auto-hospedado vía Cloudflare Tunnel (ver docker-compose.yml del backend,
  // servicio "cloudflared"). Cada vez que reinicias el túnel (docker compose
  // up), Cloudflare genera una URL nueva — cópiala de los logs:
  //   docker compose logs -f cloudflared
  // y pégala aquí abajo (con "https://" y sin barra al final) antes de
  // compilar/correr la app.
  static const String _tunnelHost = 'https://stud-civilian-sims-electronic.trycloudflare.com';

  static String get baseUrl => '$_tunnelHost/api/v1';
}
