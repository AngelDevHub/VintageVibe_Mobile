# VintageVibe_Mobile

Aplicación móvil multiplataforma (**Android / iOS PWA**) para el marketplace de moda circular **VintageVibe**, desarrollada con **Flutter**, **Riverpod**, **GoRouter**, **Dio**, **SQLite (`sqflite`)** y **SecureStorage**.

## Características principales
- Autenticación JWT segura con validaciones de entrada y logs sanitizados.
- Catálogo de prendas vintage con caché estructurado offline en SQLite (`LocalCatalogDatabase`).
- Publicación C2C con carga de imágenes compatible con Móvil y Web/PWA.
- Carrito de compras con validación preventiva de stock en tiempo real y resiliencia ante errores HTTP.
- Checkout con validación de direcciones y métodos de pago sincronizados con el backend.
- Puente de notificaciones de alta prioridad para Smartwatch **Wear OS**.
- Soporte **PWA** optimizado para iPhone (Safari iOS).

## Configuración local
1. Copia la plantilla de variables de entorno:
   ```bash
   cp .env.example .env
   ```
2. Instala dependencias:
   ```bash
   flutter pub get
   ```
3. Ejecuta las pruebas automatizadas:
   ```bash
   flutter test --reporter expanded
   ```
