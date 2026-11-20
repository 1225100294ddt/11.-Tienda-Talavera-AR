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
- 
## Prueba de pago
La pasarela es **simulada** y nunca cobra dinero real. Para probar una compra aprobada usa:
- Tarjeta: `4242 4242 4242 4242`
- Código postal: `37800`
- Teléfono: cualquier número de 10 dígitos

El checkout solicita calle, colonia, código postal y teléfono. Inicia sesión primero desde la pestaña Perfil.
<img width="3840" height="2160" alt="133832879723769121" src="https://github.com/user-attachments/assets/0668b06f-24fc-4759-af68-569e060475e2" />


