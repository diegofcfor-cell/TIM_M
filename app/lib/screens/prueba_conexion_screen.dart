import 'package:flutter/material.dart';
import 'package:laravel_reverb/laravel_reverb.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../state/prueba_conexion.dart';

/// Pantalla de la fase 1: prueba que la app llega a Laravel (HTTP)
/// y que recibe avisos en vivo desde Reverb (WebSocket).
class PruebaConexionScreen extends StatefulWidget {
  const PruebaConexionScreen({super.key});

  @override
  State<PruebaConexionScreen> createState() => _PruebaConexionScreenState();
}

class _PruebaConexionScreenState extends State<PruebaConexionScreen> {
  final _mensaje = TextEditingController(text: '¡Hola a todos!');
  final _servidor = TextEditingController(text: Config.host);
  String? _errorServidor;

  @override
  void dispose() {
    _mensaje.dispose();
    _servidor.dispose();
    super.dispose();
  }

  Future<void> _guardarServidor() async {
    final texto = _servidor.text.trim();
    if (!Config.hostValido(texto)) {
      setState(
        () => _errorServidor = 'Escribí solo la IP o la dirección, sin http://',
      );
      return;
    }
    setState(() => _errorServidor = null);
    await Config.guardarHost(texto);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Guardado. Cerrá la app y volvé a abrirla para usarlo.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prueba = context.watch<PruebaConexion>();

    return Scaffold(
      appBar: AppBar(title: const Text('TriviaLive: prueba de conexión')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Así el mismo .apk sirve en cualquier red Wi-Fi: cada uno escribe
          // la IP de la compu donde corre Laravel.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Servidor',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _servidor,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: 'IP de la compu o dirección en internet',
                      helperText: 'Ahora: ${Config.host}',
                      errorText: _errorServidor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _guardarServidor,
                    child: const Text('Guardar servidor'),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '1. HTTP: la app pregunta',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(prueba.respuestaHttp),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: prueba.probarHttp,
                    child: const Text('Probar la API'),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '2. WebSocket: el servidor avisa',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _EstadoWebSocket(estado: prueba.estadoWebSocket),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _mensaje,
                    decoration: const InputDecoration(
                      labelText: 'Mensaje para todos',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => prueba.enviarATodos(_mensaje.text),
                    child: const Text('Enviar a todos'),
                  ),
                  const SizedBox(height: 8),
                  if (prueba.mensajesRecibidos.isEmpty)
                    const Text('Todavía no llegó ningún mensaje'),
                  for (final mensaje in prueba.mensajesRecibidos)
                    ListTile(
                      leading: const Icon(Icons.bolt),
                      title: Text(mensaje),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoWebSocket extends StatelessWidget {
  const _EstadoWebSocket({required this.estado});

  final ReverbState estado;

  @override
  Widget build(BuildContext context) {
    final (texto, color) = switch (estado) {
      ReverbState.connected => ('Conectado a Reverb', Colors.green),
      ReverbState.connecting => ('Conectando...', Colors.orange),
      ReverbState.reconnecting => ('Reconectando...', Colors.orange),
      ReverbState.failed => ('No se pudo conectar', Colors.red),
      ReverbState.disconnected => ('Desconectado', Colors.grey),
    };
    return Row(
      children: [
        Icon(Icons.circle, size: 12, color: color),
        const SizedBox(width: 8),
        Text(texto),
      ],
    );
  }
}
