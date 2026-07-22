# ── Farmacare Web ─────────────────────────────────────────
# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Instalar dependencias
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copiar código y compilar
COPY . .
RUN flutter build web --release

# Stage 2: Servir con nginx
FROM nginx:alpine

# Copiar build
COPY --from=builder /app/build/web /usr/share/nginx/html

# Configuración nginx con soporte SPA
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
