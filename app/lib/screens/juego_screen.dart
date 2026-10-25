import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/juego.dart';
import '../state/sala_actual.dart';

/// Colores y figuras de las 4 opciones. La figura ayuda a quien no
/// distingue bien los colores.
const _colores = [Colors.red, Colors.blue, Colors.amber, Colors.green];
const _figuras = [
  Icons.change_history,
  Icons.diamond,
  Icons.circle,
  Icons.square,
];

/// La partida en vivo. Todo lo que cambia acá llega por Reverb:
/// PreguntaMostrada, RespuestaRecibida, PreguntaCerrada y PartidaTerminada.
class JuegoScreen extends StatelessWidget {
  const JuegoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final salaActual = context.watch<SalaActual>();
    final sala = salaActual.sala!;

    final cuerpo = switch (salaActual.fase) {
      FaseJuego.terminada => _Fin(salaActual: salaActual),
      _ => _Pregunta(salaActual: salaActual),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('${sala.tema.nombre} · ${sala.codigo}'),
        backgroundColor: sala.tema.color,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(child: cuerpo),
    );
  }
}

class _Pregunta extends StatelessWidget {
  const _Pregunta({required this.salaActual});

  final SalaActual salaActual;

  @override
  Widget build(BuildContext context) {
    final pregunta = salaActual.pregunta!;
    final resultado = salaActual.resultado;
    final cerrada = salaActual.fase == FaseJuego.resultado;
    final esTablet = MediaQuery.sizeOf(context).width > 600;
    final textos = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pregunta ${pregunta.posicion} de ${pregunta.total}',
                  style: textos.titleMedium,
                ),
              ),
              _Reloj(segundos: salaActual.segundosRestantes),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: pregunta.segundos == 0
                ? 0
                : salaActual.segundosRestantes / pregunta.segundos,
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          Text(
            pregunta.texto,
            style: esTablet ? textos.headlineMedium : textos.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: esTablet ? 2.4 : 1.3,
              children: [
                for (final (i, opcion) in pregunta.opciones.indexed)
                  _BotonOpcion(
                    indice: i,
                    opcion: opcion,
                    elegida: salaActual.miRespuestaId == opcion.id,
                    resultado: resultado,
                    onTap:
                        salaActual.soyAnfitrion ||
                            cerrada ||
                            salaActual.miRespuestaId != null
                        ? null
                        : () => salaActual.responder(opcion.id),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PiePregunta(salaActual: salaActual),
        ],
      ),
    );
  }
}

class _Reloj extends StatelessWidget {
  const _Reloj({required this.segundos});

  final int segundos;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 26,
      backgroundColor: segundos <= 5 ? Colors.red : Colors.black87,
      child: Text(
        '$segundos',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _BotonOpcion extends StatelessWidget {
  const _BotonOpcion({
    required this.indice,
    required this.opcion,
    required this.elegida,
    required this.resultado,
    required this.onTap,
  });

  final int indice;
  final OpcionPregunta opcion;
  final bool elegida;
  final ResultadoPregunta? resultado;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final resultado = this.resultado;
    final esCorrecta = resultado?.opcionCorrectaId == opcion.id;
    // Al cerrar, las incorrectas se apagan y la correcta queda marcada.
    final apagada = resultado != null && !esCorrecta;

    return Opacity(
      opacity: apagada ? 0.35 : 1,
      child: Material(
        color: _colores[indice % 4],
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: elegida
                  ? Border.all(color: Colors.black, width: 4)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  esCorrecta ? Icons.check_circle : _figuras[indice % 4],
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    opcion.texto,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Debajo de las opciones: cuántos respondieron, el resultado y, para el
/// anfitrión, el botón para seguir.
class _PiePregunta extends StatelessWidget {
  const _PiePregunta({required this.salaActual});

  final SalaActual salaActual;

  @override
  Widget build(BuildContext context) {
    final resultado = salaActual.resultado;
    final textos = Theme.of(context).textTheme;
    final mensajes = <Widget>[];

    if (salaActual.error != null) {
      mensajes.add(
        Text(
          salaActual.error!,
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    if (resultado == null) {
      final texto = salaActual.soyAnfitrion
          ? '${salaActual.respondieron} de ${salaActual.jugadoresEnPartida} '
                'respondieron'
          : salaActual.miRespuestaId != null
          ? '¡Listo! Esperando a los demás...'
          : '¡Elegí una opción!';
      mensajes.add(
        Text(texto, textAlign: TextAlign.center, style: textos.titleMedium),
      );
    } else {
      if (!salaActual.soyAnfitrion) {
        final acerte = salaActual.miRespuestaId == resultado.opcionCorrectaId;
        mensajes.add(
          Text(
            salaActual.miRespuestaId == null
                ? 'No llegaste a responder'
                : acerte
                ? '¡Correcto!'
                : 'Esta vez no',
            textAlign: TextAlign.center,
            style: textos.headlineSmall,
          ),
        );
      }
      mensajes.add(
        Text(
          '${resultado.acertaron} de ${resultado.jugadores} acertaron',
          textAlign: TextAlign.center,
          style: textos.titleMedium,
        ),
      );
      if (salaActual.soyAnfitrion) {
        mensajes.add(const SizedBox(height: 8));
        mensajes.add(
          FilledButton(
            onPressed: salaActual.enviando ? null : salaActual.siguiente,
            child: Text(
              resultado.esUltima ? 'Ver el final' : 'Siguiente pregunta',
            ),
          ),
        );
      } else {
        mensajes.add(const Text('Esperá la próxima pregunta.'));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: mensajes,
    );
  }
}

class _Fin extends StatelessWidget {
  const _Fin({required this.salaActual});

  final SalaActual salaActual;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 96, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              '¡Fin de la partida!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            // Los puntos y el podio llegan en la fase 6.
            const Text(
              'Pronto vas a ver acá los puntos y el podio.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((ruta) => ruta.isFirst),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}
