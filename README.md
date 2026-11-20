# 11. Tienda de Talavera AR

Aplicación Flutter de comercio electrónico de demostración inspirada en el manual **Talavera Dolores: tienda móvil completa**.

## Funciones incluidas
- Catálogo con búsqueda y filtros por categoría.
- Detalle de producto y existencias.
- Carrito con cantidades, persistencia local, cupones `DOLORES10` y `TALAVERA15`, envío de $99 y envío gratis desde $800.
- Perfil local de demostración.
- Checkout con validación básica de dirección y pago simulado.
- Visor 3D y botón de realidad aumentada con `model_viewer_plus` para el producto que incluye modelo.
- Pruebas básicas con `flutter_test`.

## Requisitos
- Flutter SDK instalado y agregado al PATH.
- Android Studio o Visual Studio Code con la extensión Flutter.
- Un emulador Android o teléfono físico para ejecutar la app.

## Preparar y ejecutar en Windows
1. Descomprime la carpeta.
2. Abre la carpeta `Tienda_Talavera_AR` en Visual Studio Code.
3. Abre una terminal en esa carpeta.
4. Ejecuta:

```bash
flutter create .
flutter pub get
flutter test
flutter run
```

`flutter create .` genera los archivos nativos de Android/iOS para la versión de Flutter instalada, conservando el código de `lib/` y `test/`. Si pregunta si desea sobrescribir archivos de plataforma, conserva los archivos Dart del proyecto.

También puedes ejecutar `preparar_y_ejecutar.bat` con Flutter ya instalado.

## Prueba de pago
La pasarela es **simulada** y nunca cobra dinero real. Para probar una compra aprobada usa:
- Tarjeta: `4242 4242 4242 4242`
- Código postal: `37800`
- Teléfono: cualquier número de 10 dígitos

El checkout solicita calle, colonia, código postal y teléfono. Inicia sesión primero desde la pestaña Perfil.

## Realidad aumentada
El producto “Jarrón Talavera azul” utiliza un modelo GLB de demostración alojado en `modelviewer.dev` (un astronauta de ejemplo, no una pieza real de Talavera). El visor 3D funciona en más dispositivos; la colocación AR depende de compatibilidad del teléfono, ARCore/Scene Viewer en Android o Quick Look en iOS y conexión a internet. Para entregar una AR representativa, reemplaza la URL del modelo por un archivo `.glb` propio de la pieza.

## Alcance y seguridad
Este proyecto es académico. La autenticación y el pago son demostraciones locales, no un backend real. No introduzcas datos bancarios reales. No se almacenan números de tarjeta ni CVV. Para producción se necesita servidor HTTPS, autenticación segura y pasarela certificada (Stripe, Mercado Pago o Conekta).
