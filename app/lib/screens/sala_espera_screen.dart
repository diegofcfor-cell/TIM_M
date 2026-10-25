import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/sala.dart';
import '../state/sala_actual.dart';

/// Sala de espera. El anfitrión ve el código y el QR; todos ven quién entró.
///
/// La lista de jugadores se actualiza sola: cuando alguien entra, Laravel
/// emite JugadorSeUnio y Reverb nos lo entrega por WebSocket.
class SalaEsperaScreen extends StatelessWidget {
  const SalaEsperaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final salaActual = context.watch<SalaActual>();
    final sala = salaActual.sala!;
    final esTablet = MediaQuery.sizeOf(context).width > 600;

    final datosSala = salaActual.soyAnfitrion
        ? _CodigoYQr(sala: sala)
        : _Esperando(sala: sala);
    final lista = _ListaJugadores(salaActual: salaActual);

    return Scaffold(
      appBar: AppBar(
        title: Text('Sala ${sala.codigo}'),
        backgroundColor: sala.tema.color,
        foregroundColor: Colors.white,
      ),
      body: esTablet
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: SingleChildScrollView(child: datosSala)),
                Expanded(child: lista),
              ],
            )
          : ListView(children: [datosSala, lista]),
    );
  }
}

class _CodigoYQr extends StatelessWidget {
  const _CodigoYQr({required this.sala});

  final Sala sala;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('Escaneen el QR o escriban el código:'),
          const SizedBox(height: 8),
          SelectableText(
            sala.codigo,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 16),
          // El QR guarda solo el código; la app del jugador lo lee con la cámara.
          QrImageView(
            data: sala.codigo,
            size: 220,
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            '${sala.tema.nombre} · ${sala.totalPreguntas} preguntas · '
            '${sala.segundosPorPregunta} s por pregunta',
          ),
        ],
      ),
    );
  }
}

class _Esperando extends StatelessWidget {
  const _Esperando({required this.sala});

  final Sala sala;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(sala.tema.icono, size: 64, color: sala.tema.color),
          const SizedBox(height: 8),
          Text(
            '¡Estás adentro!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Tema: ${sala.tema.nombre}. Esperá a que ${sala.anfitrion} '
            'empiece la partida.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ListaJugadores extends StatelessWidget {
  const _ListaJugadores({required this.salaActual});

  final SalaActual salaActual;

  @override
  Widget build(BuildContext context) {
    final jugadores = salaActual.sala!.jugadores;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Jugadores (${jugadores.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (jugadores.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Todavía no entró nadie.'),
            ),
          for (final jugador in jugadores)
            ListTile(
              leading: CircleAvatar(child: Text(jugador.apodo[0])),
              title: Text(jugador.apodo),
              trailing: jugador.id == salaActual.miJugadorId
                  ? const Chip(label: Text('Vos'))
                  : null,
            ),
          const SizedBox(height: 8),
          _EstadoEnVivo(enVivo: salaActual.enVivo),
          // Si se corta Reverb, se puede seguir actualizando a mano.
          if (!salaActual.enVivo)
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(
                salaActual.actualizando
                    ? 'Actualizando...'
                    : 'Actualizar lista',
              ),
              onPressed: salaActual.actualizando ? null : salaActual.actualizar,
            ),
        ],
      ),
    );
  }
}

class _EstadoEnVivo extends StatelessWidget {
  const _EstadoEnVivo({required this.enVivo});

  final bool enVivo;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.circle,
          size: 12,
          color: enVivo ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            enVivo
                ? 'En vivo: los jugadores aparecen solos'
                : 'Sin conexión en vivo',
          ),
        ),
      ],
    );
  }
}
