import 'package:flutter/foundation.dart';

import '../models/sala.dart';
import '../services/almacenamiento.dart';
import '../services/api_service.dart';

/// La sala en la que estoy, como anfitrión o como jugador.
class SalaActual extends ChangeNotifier {
  SalaActual({required this.api, required this.almacenamiento});

  final ApiService api;
  final Almacenamiento almacenamiento;

  Sala? sala;
  bool soyAnfitrion = false;
  int? miJugadorId;
  bool actualizando = false;

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
  }

  Future<void> unirse(String codigo, String apodo) async {
    final datos = await api.unirse(codigo, apodo);
    await almacenamiento.guardarTokenJugador(datos.sala.codigo, datos.token);
    sala = datos.sala;
    soyAnfitrion = false;
    miJugadorId = datos.jugadorId;
    notifyListeners();
  }

  /// Vuelve a pedir la sala a Laravel. En la fase 3 hay que tocar un botón;
  /// en la fase 4 Reverb nos va a avisar solo cuando entre alguien.
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
}
