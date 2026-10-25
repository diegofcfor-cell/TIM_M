import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tema.dart';
import '../state/temas.dart';
import 'prueba_conexion_screen.dart';

/// Pantalla de la fase 2: muestra los temas que vienen de la base de datos.
class TemasScreen extends StatelessWidget {
  const TemasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final temas = context.watch<Temas>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Elegí un tema'),
        actions: [
          IconButton(
            tooltip: 'Prueba de conexión',
            icon: const Icon(Icons.wifi_tethering),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PruebaConexionScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: temas.cargar,
        child: _Contenido(temas: temas),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.temas});

  final Temas temas;

  @override
  Widget build(BuildContext context) {
    if (temas.cargando && temas.lista.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (temas.error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(temas.error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: temas.cargar,
            child: const Text('Reintentar'),
          ),
        ],
      );
    }
    // En tablet entran más columnas que en el celular.
    final columnas = MediaQuery.sizeOf(context).width > 600 ? 3 : 2;
    return GridView.count(
      crossAxisCount: columnas,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [for (final tema in temas.lista) _TarjetaTema(tema: tema)],
    );
  }
}

class _TarjetaTema extends StatelessWidget {
  const _TarjetaTema({required this.tema});

  final Tema tema;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tema.color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Elegiste ${tema.nombre}. Crear la sala llega en la fase 3.',
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(tema.icono, size: 48, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                tema.nombre,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${tema.cantidadPreguntas} preguntas',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
