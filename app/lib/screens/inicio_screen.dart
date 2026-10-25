import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/sesion.dart';
import 'login_screen.dart';
import 'prueba_conexion_screen.dart';
import 'temas_screen.dart';
import 'unirse_screen.dart';

/// Pantalla de inicio: ¿creás una sala o te unís a una?
class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<Sesion>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('TriviaLive'),
        actions: [
          IconButton(
            tooltip: 'Prueba de conexión',
            icon: const Icon(Icons.wifi_tethering),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PruebaConexionScreen()),
            ),
          ),
          if (sesion.iniciada)
            IconButton(
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout),
              onPressed: sesion.cerrar,
            ),
        ],
      ),
      // Se puede deslizar por si el celular está acostado.
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/imagenes/icono.png',
                        width: 128,
                        height: 128,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '¡Preguntas en vivo!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 48),
                  _BotonGrande(
                    icono: Icons.add_circle,
                    texto: 'Crear una sala',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => sesion.iniciada
                            ? const TemasScreen()
                            : const LoginScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _BotonGrande(
                    icono: Icons.login,
                    texto: 'Unirme a una sala',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const UnirseScreen()),
                    ),
                  ),
                  if (sesion.iniciada) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Anfitrión: ${sesion.nombre}',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BotonGrande extends StatelessWidget {
  const _BotonGrande({
    required this.icono,
    required this.texto,
    required this.onPressed,
  });

  final IconData icono;
  final String texto;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        textStyle: const TextStyle(fontSize: 20),
      ),
      icon: Icon(icono),
      label: Text(texto),
      onPressed: onPressed,
    );
  }
}
