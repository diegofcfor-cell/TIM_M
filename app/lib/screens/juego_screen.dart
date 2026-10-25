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
        actions: [_BotonSilencio(salaActual: salaActual)],
      ),
      body: SafeArea(child: cuerpo),
    );
  }
}

class _BotonSilencio extends StatelessWidget {
  const _BotonSilencio({required this.salaActual});

  final SalaActual salaActual;

  @override
  Widget build(BuildContext context) {
    final efectos = salaActual.efectos;
    return ValueListenableBuilder(
      valueListenable: efectos.silencio,
      builder: (context, silencio, _) => IconButton(
        tooltip: silencio ? 'Activar sonidos' : 'Silenciar',
        icon: Icon(silencio ? Icons.volume_off : Icons.volume_up),
        onPressed: efectos.cambiarSilencio,
      ),
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
    final pantalla = MediaQuery.sizeOf(context);
    // Una tablet tiene su lado más corto de 600 o más, esté parada o acostada.
    final esTablet = pantalla.shortestSide >= 600;
    // Celular acostado: poca altura, así que ponemos todo en dos columnas.
    final celularAcostado = !esTablet && pantalla.width > pantalla.height;
    final textos = Theme.of(context).textTheme;

    final encabezado = [
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
        borderRadius: BorderRadius.circular(4),
      ),
      const SizedBox(height: 16),
      Text(
        pregunta.texto,
        style: esTablet ? textos.headlineMedium : textos.titleLarge,
        textAlign: TextAlign.center,
      ),
    ];

    final opciones = GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: esTablet || celularAcostado ? 2.4 : 1.3,
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
    );
    final pie = _PiePregunta(salaActual: salaActual);

    if (celularAcostado) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                children: [...encabezado, const SizedBox(height: 12), pie],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: opciones),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, espacio) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...encabezado,
            const SizedBox(height: 16),
            Expanded(child: opciones),
            const SizedBox(height: 12),
            // El resultado puede ser largo (ranking + botón): si no entra,
            // se puede deslizar, pero nunca tapa las opciones.
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: espacio.maxHeight * 0.45),
              child: SingleChildScrollView(child: pie),
            ),
          ],
        ),
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
      final miPuesto = salaActual.miPuesto;
      if (!salaActual.soyAnfitrion) {
        final acerte = salaActual.miRespuestaId == resultado.opcionCorrectaId;
        final sume = miPuesto?.puntosPregunta ?? 0;
        mensajes.add(
          Text(
            salaActual.miRespuestaId == null
                ? 'No llegaste a responder'
                : acerte
                ? '¡Correcto! +$sume puntos'
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
      if (miPuesto != null) {
        mensajes.add(
          Text(
            'Vas ${miPuesto.posicion}° con ${miPuesto.puntos} puntos',
            textAlign: TextAlign.center,
          ),
        );
      }
      if (salaActual.soyAnfitrion) {
        // El anfitrión muestra quién va ganando en la pantalla grande.
        mensajes.add(_TopRanking(ranking: salaActual.ranking));
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

/// Los primeros 5, en una lista compacta.
class _TopRanking extends StatelessWidget {
  const _TopRanking({required this.ranking});

  final List<PuestoRanking> ranking;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          for (final puesto in ranking.take(5))
            Row(
              children: [
                SizedBox(width: 32, child: Text('${puesto.posicion}°')),
                Expanded(
                  child: Text(puesto.apodo, overflow: TextOverflow.ellipsis),
                ),
                if (puesto.puntosPregunta > 0)
                  Text(
                    '+${puesto.puntosPregunta}  ',
                    style: const TextStyle(color: Colors.green),
                  ),
                Text(
                  '${puesto.puntos}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// El final: podio con los 3 primeros y la lista del resto.
class _Fin extends StatelessWidget {
  const _Fin({required this.salaActual});

  final SalaActual salaActual;

  @override
  Widget build(BuildContext context) {
    final ranking = salaActual.ranking;
    final miPuesto = salaActual.miPuesto;
    final textos = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.emoji_events, size: 72, color: Colors.amber),
        Text(
          '¡Fin de la partida!',
          textAlign: TextAlign.center,
          style: textos.headlineMedium,
        ),
        if (miPuesto != null) ...[
          const SizedBox(height: 8),
          Text(
            'Terminaste ${miPuesto.posicion}° de ${ranking.length} '
            'con ${miPuesto.puntos} puntos',
            textAlign: TextAlign.center,
            style: textos.titleMedium,
          ),
        ],
        const SizedBox(height: 24),
        _Podio(ranking: ranking, miJugadorId: salaActual.miJugadorId),
        for (final puesto in ranking.skip(3))
          ListTile(
            leading: Text('${puesto.posicion}°', style: textos.titleMedium),
            title: Text(puesto.apodo),
            trailing: Text('${puesto.puntos}'),
            selected: puesto.jugadorId == salaActual.miJugadorId,
          ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () =>
              Navigator.of(context).popUntil((ruta) => ruta.isFirst),
          child: const Text('Volver al inicio'),
        ),
      ],
    );
  }
}

/// Tres escalones: el 2° a la izquierda, el 1° en el medio (más alto)
/// y el 3° a la derecha, como en un podio de verdad.
class _Podio extends StatelessWidget {
  const _Podio({required this.ranking, required this.miJugadorId});

  final List<PuestoRanking> ranking;
  final int? miJugadorId;

  static const _alturas = [140.0, 100.0, 70.0];
  static const _colores = [
    Color(0xFFFFC107), // oro
    Color(0xFFB0BEC5), // plata
    Color(0xFFCD7F32), // bronce
  ];

  @override
  Widget build(BuildContext context) {
    // Orden en pantalla: 2°, 1°, 3°.
    final lugares = [1, 0, 2].where((i) => i < ranking.length);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final i in lugares)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  Text(
                    ranking[i].apodo,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: ranking[i].jugadorId == miJugadorId
                          ? TextDecoration.underline
                          : null,
                    ),
                  ),
                  Text('${ranking[i].puntos} pts'),
                  const SizedBox(height: 4),
                  Container(
                    height: _alturas[i],
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _colores[i],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      '${ranking[i].posicion}°',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
