import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:laravel_reverb/laravel_reverb.dart';

import '../models/sala.dart';
import '../services/almacenamiento.dart';
import '../services/api_service.dart';
import '../services/realtime_service.dart';

/// La sala en la que estoy, como anfitrión o como jugador.
class SalaActual extends ChangeNotifier {
  SalaActual({
    required this.api,
    required this.almacenamiento,
    required this.realtime,
  });

  final ApiService api;
  final Almacenamiento almacenamiento;
  final RealtimeService realtime;

  Sala? sala;
  bool soyAnfitrion = false;
  int? miJugadorId;
  bool actualizando = false;

  /// true cuando estamos conectados a Reverb y los cambios llegan solos.
  bool get enVivo => _estadoReverb == ReverbState.connected;

  ReverbState _estadoReverb = ReverbState.disconnected;
  StreamSubscription<ReverbState>? _estados;
  Cancelar? _dejarDeEscuchar;

  Future<void> crear({
    required int temaId,
    required int segundos,
    required int cantidadPreguntas,
  }) async {
    sala = await api.crearSala(
      temaId: temaId,
      segundos: segundos,
      cantidadPreguntas: cantidadPreguntas,
    );
    soyAnfitrion = true;
    miJugadorId = null;
    notifyListeners();
    await _escucharSala();
  }

  Future<void> unirse(String codigo, String apodo) async {
    final datos = await api.unirse(codigo, apodo);
    await almacenamiento.guardarTokenJugador(datos.sala.codigo, datos.token);
    sala = datos.sala;
    soyAnfitrion = false;
    miJugadorId = datos.jugadorId;
    notifyListeners();
    await _escucharSala();
  }

  /// Vuelve a pedir la sala a Laravel por HTTP. Solo hace falta si se
  /// cortó la conexión con Reverb.
  Future<void> actualizar() async {
    final actual = sala;
    if (actual == null) return;
    actualizando = true;
    notifyListeners();
    try {
      sala = await api.verSala(actual.codigo);
    } finally {
      actualizando = false;
      notifyListeners();
    }
  }

  /// Fase 4: nos suscribimos al canal de la sala. Cada vez que Laravel
  /// emite JugadorSeUnio, Reverb nos lo entrega y agregamos al jugador.
  Future<void> _escucharSala() async {
    final codigo = sala!.codigo;
    _dejarDeEscuchar?.call();
    _dejarDeEscuchar = realtime.escucharSala(
      codigo,
      alUnirseJugador: (jugador) {
        if (sala?.codigo != codigo) return;
        sala = sala!.conJugador(jugador);
        notifyListeners();
      },
    );

    _estados ??= realtime.estados.listen((estado) {
      _estadoReverb = estado;
      notifyListeners();
    });
    _estadoReverb = realtime.estado;

    try {
      await realtime.conectar();
    } catch (_) {
      // Sin Reverb la sala sigue funcionando con el botón "Actualizar".
    }
    // Por si alguien entró justo antes de que empezáramos a escuchar.
    await actualizar();
  }

  @override
  void dispose() {
    _dejarDeEscuchar?.call();
    _estados?.cancel();
    super.dispose();
  }
}
