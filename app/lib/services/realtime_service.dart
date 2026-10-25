import 'package:laravel_reverb/laravel_reverb.dart';

import '../config.dart';

/// Mantiene abierta la conexión WebSocket con Reverb y escucha canales.
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

  Future<void> conectar() => reverb.connect();

  /// Escucha el evento PingEnviado en el canal público "pruebas".
  Subscription escucharPruebas(void Function(Map<String, dynamic>) alRecibir) {
    return reverb.channel('pruebas').listen('PingEnviado', alRecibir);
  }

  void dispose() => reverb.dispose();
}
