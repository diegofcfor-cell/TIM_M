import 'package:laravel_reverb/laravel_reverb.dart';

import '../config.dart';
import '../models/sala.dart';

/// Función para dejar de escuchar un canal.
typedef Cancelar = void Function();

/// Mantiene abierta la conexión WebSocket con Reverb y escucha canales.
///
/// Toda la app comparte una sola conexión: se crea una vez en main.dart.
class RealtimeService {
  RealtimeService()
    : reverb = Reverb(
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

  /// Escucha el canal de una sala ("sala.KX7P2A").
  /// Laravel emite JugadorSeUnio cada vez que alguien entra.
  Cancelar escucharSala(
    String codigo, {
    required void Function(Jugador jugador) alUnirseJugador,
  }) {
    return reverb.channel('sala.$codigo').listen('JugadorSeUnio', (datos) {
      alUnirseJugador(
        Jugador.fromJson(datos['player'] as Map<String, dynamic>),
      );
    }).cancel;
  }

  void dispose() => reverb.dispose();
}
