import 'package:laravel_reverb/laravel_reverb.dart';

import '../config.dart';
import '../models/juego.dart';
import '../models/sala.dart';

/// Función para dejar de escuchar un canal.
typedef Cancelar = void Function();

/// Qué hacer con cada evento que Laravel emite en el canal de la sala.
class EventosSala {
  const EventosSala({
    this.alUnirseJugador,
    this.alIniciarPartida,
    this.alMostrarPregunta,
    this.alRecibirRespuesta,
    this.alCerrarPregunta,
    this.alTerminarPartida,
  });

  final void Function(Jugador jugador)? alUnirseJugador;
  final void Function()? alIniciarPartida;
  final void Function(Pregunta pregunta)? alMostrarPregunta;
  final void Function(int respondieron, int jugadores)? alRecibirRespuesta;
  final void Function(ResultadoPregunta resultado)? alCerrarPregunta;
  final void Function()? alTerminarPartida;
}

/// Mantiene abierta la conexión WebSocket con Reverb y escucha canales.
///
/// Toda la app comparte una sola conexión: se crea una vez en main.dart.
class RealtimeService {
  /// Se puede pasar otro [reverb] para probar sin la app completa.
  RealtimeService({Reverb? reverb})
    : reverb =
          reverb ??
          Reverb(
            host: Config.host,
            port: Config.reverbPort,
            appKey: Config.reverbAppKey,
            useTls: false,
          );

  final Reverb reverb;

  Stream<ReverbState> get estados => reverb.states;

  ReverbState get estado => reverb.state;

  /// Abre la conexión. Si ya está abierta, no hace nada.
  Future<void> conectar() => reverb.connect();

  /// Escucha el evento PingEnviado en el canal público "pruebas".
  Cancelar escucharPruebas(void Function(Map<String, dynamic>) alRecibir) {
    return reverb.channel('pruebas').listen('PingEnviado', alRecibir).cancel;
  }

  /// Escucha el canal de una sala ("sala.KX7P2A"). Cada nombre es una
  /// clase de app/Events en Laravel.
  Cancelar escucharSala(String codigo, EventosSala eventos) {
    return reverb
        .channel('sala.$codigo')
        .listen('JugadorSeUnio', (datos) {
          eventos.alUnirseJugador?.call(
            Jugador.fromJson(datos['player'] as Map<String, dynamic>),
          );
        })
        .listen('PartidaIniciada', (_) => eventos.alIniciarPartida?.call())
        .listen('PreguntaMostrada', (datos) {
          eventos.alMostrarPregunta?.call(Pregunta.fromJson(datos));
        })
        .listen('RespuestaRecibida', (datos) {
          eventos.alRecibirRespuesta?.call(
            datos['answered'] as int,
            datos['players'] as int,
          );
        })
        .listen('PreguntaCerrada', (datos) {
          eventos.alCerrarPregunta?.call(ResultadoPregunta.fromJson(datos));
        })
        .listen('PartidaTerminada', (_) => eventos.alTerminarPartida?.call())
        .cancel;
  }

  void dispose() => reverb.dispose();
}
