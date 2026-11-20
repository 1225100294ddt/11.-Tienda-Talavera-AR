import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TalaveraApp());
}

const azul = Color(0xFF123B68);
const crema = Color(0xFFFFF8EC);
const terracota = Color(0xFFB85C38);

class Producto {
  final String id, nombre, descripcion, categoria, emoji;
  final int precio, existencias;
  final String? modelo;
  const Producto(this.id, this.nombre, this.descripcion, this.precio,
      this.existencias, this.categoria, this.emoji, {this.modelo});
  bool get tieneModelo3d => modelo != null &&
      (modelo!.startsWith('https://') || modelo!.startsWith('assets/'));
}

const productos = <Producto>[
  Producto('j1', 'Jarrón Talavera azul', 'Jarrón artesanal pintado a mano con flores y detalles en azul cobalto.', 125000, 8, 'Talavera', '🏺', modelo: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb'),
  Producto('p1', 'Plato decorativo floral', 'Plato de cerámica decorado a mano, ideal para exhibir.', 68000, 12, 'Talavera', '🍽️'),
  Producto('t1', 'Taza tradicional', 'Taza artesanal con acabado brillante y decoración tradicional.', 32000, 20, 'Talavera', '☕'),
  Producto('m1', 'Maceta artesanal', 'Maceta de barro con detalles pintados en azul y amarillo.', 45000, 10, 'Decoración', '🪴'),
  Producto('a1', 'Azucarera de Talavera', 'Pieza artesanal para complementar tu mesa.', 79000, 6, 'Talavera', '🏺'),
  Producto('c1', 'Juego de sal y pimienta', 'Juego de dos piezas decoradas a mano.', 55000, 9, 'Decoración', '🧂'),
];

String pesos(int centavos) {
  final p = centavos ~/ 100;
  final c = (centavos % 100).toString().padLeft(2, '0');
  final s = p.toString().replaceAllMapped(RegExp(r'\\B(?=(\\d{3})+(?!\\d))'), (_) => ',');
  return '\$$s.$c';
}

class Linea {
  final Producto producto;
  int cantidad;
  Linea(this.producto, this.cantidad);
  int get importe => producto.precio * cantidad;
}

class Carrito {
  final Map<String, Linea> lineas = {};
  static const costoEnvio = 9900;
  static const gratisDesde = 80000;
  int get subtotal => lineas.values.fold(0, (s, l) => s + l.importe);
  int get descuento => cupon == 'DOLORES10' ? (subtotal * 10 + 50) ~/ 100 :
      cupon == 'TALAVERA15' ? (subtotal * 15 + 50) ~/ 100 : 0;
  String? cupon;
  int get envio => lineas.isEmpty || subtotal - descuento >= gratisDesde ? 0 : costoEnvio;
  int get total => subtotal - descuento + envio;
  int get cantidad => lineas.values.fold(0, (s, l) => s + l.cantidad);
  void agregar(Producto p) {
    final n = (lineas[p.id]?.cantidad ?? 0) + 1;
    if (n > p.existencias || n > 10) throw Exception('No hay existencias suficientes o superaste el límite de 10 piezas.');
    lineas[p.id] = Linea(p, n);
  }
  void cambiar(Producto p, int n) {
    if (n <= 0) { lineas.remove(p.id); return; }
    if (n > p.existencias || n > 10) throw Exception('La cantidad supera las existencias disponibles.');
    lineas[p.id] = Linea(p, n);
  }
  void aplicarCupon(String texto) {
    final c = texto.trim().toUpperCase();
    if (c != 'DOLORES10' && c != 'TALAVERA15') throw Exception('Cupón no válido.');
    cupon = c;
  }
  void vaciar() { lineas.clear(); cupon = null; }
}

class TalaveraApp extends StatefulWidget {
  const TalaveraApp({super.key});
  @override
  State<TalaveraApp> createState() => _TalaveraAppState();
}
class _TalaveraAppState extends State<TalaveraApp> {
  final carrito = Carrito();
  int tab = 0;
  String? nombreUsuario;
  String correo = '';
  @override
  void initState() { super.initState(); _cargar(); }
  Future<void> _cargar() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('carrito_talavera');
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as List;
        for (final row in data) {
          final prod = productos.where((e) => e.id == row['id']).firstOrNull;
          if (prod != null) carrito.cambiar(prod, (row['cantidad'] as num).toInt());
        }
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }
  Future<void> guardar() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('carrito_talavera', jsonEncode(carrito.lineas.values.map((l) => {'id': l.producto.id, 'cantidad': l.cantidad}).toList()));
  }
  void refrescar() { setState(() {}); guardar(); }
  @override
  Widget build(BuildContext context) {
    final pages = [
      CatalogoPage(onAdd: (p) { try { carrito.agregar(p); refrescar(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${p.nombre} agregado al carrito'))); } catch(e) { _msg(e.toString()); } }, onOpen: _detalle),
      CarritoPage(carrito: carrito, onChange: (p,n) { try { carrito.cambiar(p,n); refrescar(); } catch(e) { _msg(e.toString()); } }, onCheckout: _checkout, onCoupon: (c) { try { carrito.aplicarCupon(c); refrescar(); } catch(e) { _msg(e.toString()); } }),
      PerfilPage(nombre: nombreUsuario, correo: correo, onLogin: _login, onLogout: () => setState(() { nombreUsuario = null; correo = ''; })),
    ];
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Talavera Dolores',
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: azul), scaffoldBackgroundColor: crema, appBarTheme: const AppBarTheme(backgroundColor: azul, foregroundColor: Colors.white)),
      home: Scaffold(
        appBar: AppBar(title: const Text('Talavera Dolores'), centerTitle: true, actions: [IconButton(tooltip: 'Carrito', onPressed: () => setState(() => tab = 1), icon: Badge(label: Text('${carrito.cantidad}'), child: const Icon(Icons.shopping_bag_outlined)))]),
        body: IndexedStack(index: tab, children: pages),
        bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v), destinations: const [
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Tienda'),
          NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart), label: 'Carrito'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ]),
      ),
    );
  }
  void _msg(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  void _detalle(Producto p) => Navigator.push(context, MaterialPageRoute(builder: (_) => DetallePage(producto: p, onAdd: () { try { carrito.agregar(p); refrescar(); Navigator.pop(context); _msg('Producto agregado al carrito'); } catch(e) { _msg(e.toString()); } })));
  Future<void> _login(String n, String c) async {
    setState(() { nombreUsuario = n; correo = c; });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usuario_nombre', n);
    await prefs.setString('usuario_correo', c);
  }
  void _checkout() {
    if (nombreUsuario == null) { _msg('Inicia sesión desde Perfil para continuar.'); setState(() => tab = 2); return; }
    Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutPage(carrito: carrito, nombre: nombreUsuario!, onDone: (ref) { carrito.vaciar(); refrescar(); Navigator.pop(context); _msg('¡Compra simulada aprobada! Orden $ref'); })));
  }
}

class CatalogoPage extends StatefulWidget {
  final void Function(Producto) onAdd;
  final void Function(Producto) onOpen;
  const CatalogoPage({super.key, required this.onAdd, required this.onOpen});
  @override
  State<CatalogoPage> createState() => _CatalogoPageState();
}
class _CatalogoPageState extends State<CatalogoPage> {
  String filtro = 'Todos', busqueda = '';
  @override
  Widget build(BuildContext context) {
    final lista = productos.where((p) => (filtro == 'Todos' || p.categoria == filtro) && ('${p.nombre} ${p.descripcion}'.toLowerCase().contains(busqueda.toLowerCase()))).toList();
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: Container(padding: const EdgeInsets.fromLTRB(18, 22, 18, 20), decoration: const BoxDecoration(gradient: LinearGradient(colors: [azul, Color(0xFF286B91)]), borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Artesanía hecha en Dolores Hidalgo', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6), const Text('Tradición y color en cada pieza.', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 16), TextField(decoration: InputDecoration(hintText: 'Buscar productos...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)), onChanged: (v) => setState(() => busqueda = v)),
        Wrap(
  spacing: 8,
  children: ['Todos', 'Talavera', 'Decoración'].map((c) {
    final seleccionado = filtro == c;

    return ChoiceChip(
      label: Text(c),
      selected: seleccionado,
      onSelected: (_) {
        setState(() {
          filtro = c;
        });
      },
      labelStyle: TextStyle(
        color: seleccionado ? azul : Colors.white,
      ),
      backgroundColor: Colors.white24,
      selectedColor: Colors.white,
    );
  }).toList(),
)
      ]))),
      SliverPadding(padding: const EdgeInsets.all(14), sliver: SliverGrid.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: .69, crossAxisSpacing: 12, mainAxisSpacing: 12), itemCount: lista.length, itemBuilder: (_, i) {
        final p = lista[i];
        return Card(clipBehavior: Clip.antiAlias, elevation: 2, child: InkWell(onTap: () => widget.onOpen(p), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: Container(color: const Color(0xFFE9E2D4), child: Center(child: Text(p.emoji, style: const TextStyle(fontSize: 66))))),
          Padding(padding: const EdgeInsets.fromLTRB(10, 8, 10, 0), child: Text(p.nombre, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), child: Text(pesos(p.precio), style: const TextStyle(color: terracota, fontWeight: FontWeight.bold, fontSize: 16))),
          Padding(padding: const EdgeInsets.fromLTRB(6, 0, 6, 6), child: FilledButton.tonalIcon(onPressed: () => widget.onAdd(p), icon: const Icon(Icons.add_shopping_cart, size: 18), label: const Text('Agregar'))),
        ])));
      }))
    ]);
  }
}

class DetallePage extends StatelessWidget {
  final Producto producto;
  final VoidCallback onAdd;
  const DetallePage({super.key, required this.producto, required this.onAdd});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(producto.nombre)), body: ListView(padding: const EdgeInsets.all(20), children: [
    Container(height: 230, decoration: BoxDecoration(color: const Color(0xFFE9E2D4), borderRadius: BorderRadius.circular(20)), child: Center(child: Text(producto.emoji, style: const TextStyle(fontSize: 110)))),
    const SizedBox(height: 18), Text(producto.nombre, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
    Text(pesos(producto.precio), style: const TextStyle(fontSize: 23, color: terracota, fontWeight: FontWeight.bold)),
    const SizedBox(height: 12), Text(producto.descripcion), const SizedBox(height: 8), Text('Categoría: ${producto.categoria}'), Text('Existencias: ${producto.existencias}'),
    if (producto.tieneModelo3d) ...[
      const SizedBox(height: 16),
      OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArPage(producto: producto))), icon: const Icon(Icons.view_in_ar), label: const Text('Ver en tu espacio (3D / AR)')),
      const Text('La función AR requiere un dispositivo compatible.', style: TextStyle(fontSize: 12, color: Colors.black54)),
    ],
    const SizedBox(height: 20), FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_shopping_cart), label: const Text('Agregar al carrito'))
  ]));
}

class ArPage extends StatelessWidget {
  final Producto producto;
  const ArPage({super.key, required this.producto});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Ver en tu espacio')), body: ModelViewer(src: producto.modelo!, alt: 'Modelo 3D de ${producto.nombre}', ar: true, arModes: const ['scene-viewer','webxr','quick-look'], autoRotate: true, cameraControls: true, disableZoom: false, backgroundColor: const Color(0xFFF7F2E9)));
}

class CarritoPage extends StatelessWidget {
  final Carrito carrito;
  final void Function(Producto,int) onChange;
  final VoidCallback onCheckout;
  final void Function(String) onCoupon;
  const CarritoPage({super.key, required this.carrito, required this.onChange, required this.onCheckout, required this.onCoupon});
  @override
  Widget build(BuildContext context) {
    final cup = TextEditingController();
    return carrito.lineas.isEmpty ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.shopping_bag_outlined, size: 70, color: azul), SizedBox(height: 10), Text('Tu carrito está vacío', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), Text('Explora las piezas artesanales de la tienda.')])) :
    ListView(padding: const EdgeInsets.all(16), children: [
      ...carrito.lineas.values.map((l) => Card(child: ListTile(leading: CircleAvatar(backgroundColor: const Color(0xFFE9E2D4), child: Text(l.producto.emoji, style: const TextStyle(fontSize: 24))), title: Text(l.producto.nombre), subtitle: Text('${pesos(l.producto.precio)} · ${pesos(l.importe)}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(onPressed: () => onChange(l.producto, l.cantidad - 1), icon: const Icon(Icons.remove_circle_outline)), Text('${l.cantidad}'), IconButton(onPressed: () => onChange(l.producto, l.cantidad + 1), icon: const Icon(Icons.add_circle_outline))])))),
      const SizedBox(height: 12), Row(children: [Expanded(child: TextField(controller: cup, decoration: const InputDecoration(labelText: 'Cupón de descuento', border: OutlineInputBorder()))), const SizedBox(width: 8), FilledButton(onPressed: () => onCoupon(cup.text), child: const Text('Aplicar'))]),
      const SizedBox(height: 18), _totalRow('Subtotal', carrito.subtotal), _totalRow('Descuento', -carrito.descuento), _totalRow('Envío', carrito.envio), const Divider(), _totalRow('Total', carrito.total, bold: true),
      if (carrito.envio > 0) Text('Agrega ${pesos(Carrito.gratisDesde - carrito.subtotal + carrito.descuento)} para obtener envío gratis.', style: const TextStyle(color: azul)),
      const SizedBox(height: 16), FilledButton(onPressed: onCheckout, child: const Text('Continuar al pago'))
    ]);
  }
}
Widget _totalRow(String label, int value, {bool bold = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 19 : 15)), Text(pesos(value), style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 19 : 15))]));

class PerfilPage extends StatelessWidget {
  final String? nombre, correo;
  final Future<void> Function(String,String) onLogin;
  final VoidCallback onLogout;
  const PerfilPage({super.key, required this.nombre, required this.correo, required this.onLogin, required this.onLogout});
  @override
  Widget build(BuildContext context) => nombre == null ? _LoginForm(onLogin: onLogin) : Center(child: Card(margin: const EdgeInsets.all(22), child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const CircleAvatar(radius: 38, child: Icon(Icons.person, size: 42)), const SizedBox(height: 12), Text(nombre!, style: Theme.of(context).textTheme.headlineSmall), Text(correo ?? ''), const SizedBox(height: 18), const Text('Bienvenido a Talavera Dolores'), const SizedBox(height: 14), OutlinedButton.icon(onPressed: onLogout, icon: const Icon(Icons.logout), label: const Text('Cerrar sesión'))
  ]))));
}
class _LoginForm extends StatefulWidget {
  final Future<void> Function(String,String) onLogin;
  const _LoginForm({required this.onLogin});
  @override
  State<_LoginForm> createState() => _LoginFormState();
}
class _LoginFormState extends State<_LoginForm> {
  final n = TextEditingController(), c = TextEditingController();
  @override
  void dispose() { n.dispose(); c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(24), children: [
    const Icon(Icons.account_circle_outlined, size: 84, color: azul), const Text('Mi perfil', textAlign: TextAlign.center, style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
    const SizedBox(height: 20), TextField(controller: n, decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
    const SizedBox(height: 12), TextField(controller: c, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo electrónico', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email))),
    const SizedBox(height: 16), FilledButton(onPressed: () { if (n.text.trim().length < 2 || !c.text.contains('@')) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escribe un nombre y correo válidos.'))); return; } widget.onLogin(n.text.trim(), c.text.trim()); }, child: const Text('Iniciar sesión / Crear perfil')),
    const SizedBox(height: 10), const Text('Perfil local de demostración. La autenticación del manual se simula; no se conecta a un servidor.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54))
  ]);
}

class CheckoutPage extends StatefulWidget {
  final Carrito carrito;
  final String nombre;
  final void Function(String) onDone;
  const CheckoutPage({super.key, required this.carrito, required this.nombre, required this.onDone});
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}
class _CheckoutPageState extends State<CheckoutPage> {
  final calle = TextEditingController(), colonia = TextEditingController(), cp = TextEditingController(text: '37800'), telefono = TextEditingController();
  final tarjeta = TextEditingController(text: '4242 4242 4242 4242');
  bool procesando = false;
  @override
  void dispose() { calle.dispose(); colonia.dispose(); cp.dispose(); telefono.dispose(); tarjeta.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Finalizar compra')), body: ListView(padding: const EdgeInsets.all(18), children: [
    Text('Hola, ${widget.nombre}', style: Theme.of(context).textTheme.titleLarge), const Text('Datos de envío'),
    const SizedBox(height: 12), _field(calle, 'Calle y número'), _field(colonia, 'Colonia'), _field(cp, 'Código postal', type: TextInputType.number), _field(telefono, 'Teléfono (10 dígitos)', type: TextInputType.phone),
    const SizedBox(height: 12), const Text('Pago de demostración', style: TextStyle(fontWeight: FontWeight.bold)), const Text('Tarjeta de prueba aprobada: 4242 4242 4242 4242'), _field(tarjeta, 'Número de tarjeta', type: TextInputType.number),
    const SizedBox(height: 8), Text('Total a pagar: ${pesos(widget.carrito.total)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: azul)),
    const SizedBox(height: 16), FilledButton(onPressed: procesando ? null : _pagar, child: procesando ? const CircularProgressIndicator() : const Text('Confirmar pago simulado')),
    const Text('AVISO: esta pasarela es simulada. No se procesa dinero real ni se almacena la tarjeta.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.black54))
  ]));
  Widget _field(TextEditingController c, String label, {TextInputType type = TextInputType.text}) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: c, keyboardType: type, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())));
  Future<void> _pagar() async {
    if (calle.text.trim().length < 3 || colonia.text.trim().length < 3 || !RegExp(r'^\\d{5}$').hasMatch(cp.text.trim()) || !RegExp(r'^\\d{10}$').hasMatch(telefono.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Revisa calle, colonia, código postal y teléfono.'))); return;
    }
    final numero = tarjeta.text.replaceAll(RegExp(r'\\D'), '');
    if (numero != '4242424242424242') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pago rechazado en la simulación. Usa la tarjeta de prueba indicada.'))); return;
    }
    setState(() => procesando = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => procesando = false);
    widget.onDone('TLV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
  }
}
