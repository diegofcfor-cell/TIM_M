import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Lo que el juego "se siente": vibraciones, sonidos y la pantalla prendida.
///
/// Esta clase base no hace nada. Así los tests no necesitan un celular de
/// verdad: la app usa [EfectosReales], que sí vibra y suena.
class Efectos {
  /// true si el jugador apagó los sonidos (la vibración sigue igual).
  final silencio = ValueNotifier<bool>(false);

  Future<void> cargar() async {}

  void cambiarSilencio() => silencio.value = !silencio.value;

  /// Tocó una opción.
  void toque() {}

  /// Uno de los últimos 5 segundos de la cuenta regresiva.
  void tic() {}

  void acerto() {}

  void fallo() {}

  void fin() {}

  /// Que el celular no se bloquee mientras dura la partida.
  void pantallaPrendida(bool prendida) {}
}

class EfectosReales extends Efectos {
  final _reproductor = AudioPlayer();

  static const _claveSilencio = 'silencio';

  @override
  Future<void> cargar() async {
    // Los sonidos del juego son cortos: no hace falta pausar la música
    // que el usuario tenga puesta.
    await AudioPlayer.global.setAudioContext(
      AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
    );
    final prefs = await SharedPreferences.getInstance();
    silencio.value = prefs.getBool(_claveSilencio) ?? false;
  }

  @override
  void cambiarSilencio() {
    super.cambiarSilencio();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool(_claveSilencio, silencio.value),
    );
  }

  @override
  void toque() => HapticFeedback.selectionClick();

  @override
  void tic() {
    HapticFeedback.lightImpact();
    _sonar('tic');
  }

  @override
  void acerto() {
    HapticFeedback.mediumImpact();
    _sonar('correcto');
  }

  @override
  void fallo() {
    HapticFeedback.heavyImpact();
    _sonar('incorrecto');
  }

  @override
  void fin() => _sonar('fin');

  @override
  void pantallaPrendida(bool prendida) => WakelockPlus.toggle(enable: prendida);

  void _sonar(String nombre) {
    if (silencio.value) return;
    // Si el sonido falla (por ejemplo, sin parlante), el juego sigue igual.
    _reproductor.play(AssetSource('sonidos/$nombre.wav')).catchError((_) {});
  }
}
