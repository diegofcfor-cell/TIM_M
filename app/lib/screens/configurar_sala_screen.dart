import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tema.dart';
import '../state/sala_actual.dart';
import 'sala_espera_screen.dart';

/// El anfitrión elige el tiempo por pregunta y cuántas preguntas tiene la partida.
class ConfigurarSalaScreen extends StatefulWidget {
  const ConfigurarSalaScreen({super.key, required this.tema});

  final Tema tema;

  @override
  State<ConfigurarSalaScreen> createState() => _ConfigurarSalaScreenState();
}

class _ConfigurarSalaScreenState extends State<ConfigurarSalaScreen> {
  int _segundos = 30;
  int _cantidad = 10;
  bool _creando = false;
  String? _error;

  Future<void> _crear() async {
    setState(() {
      _creando = true;
      _error = null;
    });
    try {
      await context.read<SalaActual>().crear(
        temaId: widget.tema.id,
        segundos: _segundos,
        cantidadPreguntas: _cantidad,
      );
      if (!mounted) return;
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const SalaEsperaScreen()));
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _creando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tema.nombre),
        backgroundColor: widget.tema.color,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Tiempo para cada pregunta',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 30, label: Text('30 segundos')),
              ButtonSegment(value: 60, label: Text('1 minuto')),
            ],
            selected: {_segundos},
            onSelectionChanged: (valor) =>
                setState(() => _segundos = valor.first),
          ),
          const SizedBox(height: 24),
          Text(
            'Cantidad de preguntas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 5, label: Text('5')),
              ButtonSegment(value: 10, label: Text('10')),
              ButtonSegment(value: 15, label: Text('15')),
            ],
            selected: {_cantidad},
            onSelectionChanged: (valor) =>
                setState(() => _cantidad = valor.first),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 32),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.meeting_room),
            label: Text(_creando ? 'Creando...' : 'Crear la sala'),
            onPressed: _creando ? null : _crear,
          ),
        ],
      ),
    );
  }
}
