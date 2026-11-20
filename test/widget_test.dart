import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_talavera/main.dart';

void main() {
  test('formatea pesos con centavos', () {
    expect(pesos(125000), r'$1,250.00');
    expect(pesos(99), r'$0.99');
  });

  test('carrito aplica cupón y envío gratis desde 800 pesos', () {
    final c = Carrito();
    c.agregar(productos.first);
    expect(c.subtotal, 125000);
    expect(c.envio, 0);
    c.aplicarCupon(' dolores10 ');
    expect(c.descuento, 12500);
    expect(c.total, 112500);
  });

  test('producto con modelo https habilita visor 3D', () {
    expect(productos.first.tieneModelo3d, isTrue);
  });
}
