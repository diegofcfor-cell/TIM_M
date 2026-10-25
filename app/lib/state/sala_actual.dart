import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:laravel_reverb/laravel_reverb.dart';

import '../models/juego.dart';
import '../models/sala.dart';
import '../services/almacenamiento.dart';
import '../services/api_service.dart';
import '../services/efectos.dart';
import '../services/realtime_service.dart';

/// En qué momento de la partida estamos. Cada fase es una pantalla.
enum FaseJuego { espera, pregunta, resultado, terminada }

/// La sala en la que estoy, como anfitrión o como jugador.
class SalaActual extends ChangeNotifier {
  SalaActual({
    required this.api,
    required this.almacenamiento,
    required this.realtime,
    Efectos? efectos,
  }) : efectos = efectos ?? Efectos();

  final ApiService api;
  final Almacenamiento almacenamiento;
  final RealtimeService realtime;

  /// Vibraciones, sonidos y pantalla prendida.
  final Efectos efectos;

  Sala? sala;
  bool soyAnfitrion = false;
  int? miJugadorId;
  bool actualizando = false;

  FaseJuego fase = FaseJuego.espera;
  Pregunta? pregunta;
  ResultadoPregunta? resultado;

  /// La opción que toqué en la pregunta actual (null si no respondí).
  int? miRespuestaId;

  /// Cuántos respondieron la pregunta actual, de cuántos jugadores.
  int respondieron = 0;
  int jugadoresEnPartida = 0;

  /// Quién va ganando. Llega al cerrar cada pregunta y al final.
  List<PuestoRanking> ranking = const [];

  /// Mi fila del ranking (null si soy el anfitrión o todavía no hay).
  PuestoRanking? get miPuesto {
    for (final puesto in ranking) {
      if (puesto.jugadorId == miJugadorId) return puesto;
    }
    return null;
  }

  /// La cuenta regresiva que se ve en pantalla. Solo es visual: el que
  /// decide si llegaste a tiempo es el reloj de Laravel.
  int segundosRestantes = 0;

  /// Mensaje para mostrar si Laravel rechazó algo (por ejemplo, tarde).
  String? error;

  /// Un pedido a Laravel en curso (para desactivar botones).
  bool enviando = false;

  String? _tokenJugador;
  Timer? _reloj;

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
    _tokenJugador = null;
    _reiniciarJuego();
    notifyListeners();
    await _escucharSala();
  }

  Future<void> unirse(String codigo, String apodo) async {
    final datos = await api.unirse(codigo, apodo);
    await almacenamiento.guardarTokenJugador(datos.sala.codigo, datos.token);
    sala = datos.sala;
    soyAnfitrion = false;
    miJugadorId = datos.jugadorId;
    _tokenJugador = datos.token;
    _reiniciarJuego();
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

  /// Solo el anfitrión: Laravel arranca la partida y emite la primera
  /// pregunta por Reverb. La pantalla cambia cuando llega ese evento.
  Future<void> empezar() => _enviar(() => api.empezarPartida(sala!.codigo));

  /// Solo el anfitrión: pasa a la próxima pregunta (o al final).
  Future<void> siguiente() =>
      _enviar(() => api.siguientePregunta(sala!.codigo));

  /// Solo el jugador: manda la opción elegida. Se marca enseguida en
  /// pantalla y, si Laravel la rechaza, se muestra el motivo.
  Future<void> responder(int opcionId) async {
    final token = _tokenJugador;
    if (token == null || miRespuestaId != null) return;
    if (fase != FaseJuego.pregunta || segundosRestantes == 0) return;
    miRespuestaId = opcionId;
    error = null;
    efectos.toque();
    notifyListeners();
    try {
      await api.responder(sala!.codigo, token, opcionId);
    } on ApiException catch (e) {
      error = e.mensaje;
      notifyListeners();
    }
  }

  Future<void> _enviar(Future<void> Function() pedido) async {
    enviando = true;
    error = null;
    notifyListeners();
    try {
      await pedido();
    } on ApiException catch (e) {
      error = e.mensaje;
    } finally {
      enviando = false;
      notifyListeners();
    }
  }

  void _reiniciarJuego() {
    _reloj?.cancel();
    fase = FaseJuego.espera;
    pregunta = null;
    resultado = null;
    miRespuestaId = null;
    respondieron = 0;
    jugadoresEnPartida = 0;
    segundosRestantes = 0;
    ranking = const [];
    error = null;
  }

  void _mostrarPregunta(Pregunta nueva) {
    fase = FaseJuego.pregunta;
    pregunta = nueva;
    resultado = null;
    miRespuestaId = null;
    respondieron = 0;
    jugadoresEnPartida = sala!.jugadores.length;
    error = null;
    segundosRestantes = nueva.segundos;
    _reloj?.cancel();
    _reloj = Timer.periodic(const Duration(seconds: 1), (reloj) {
      segundosRestantes = segundosRestantes > 0 ? segundosRestantes - 1 : 0;
      if (segundosRestantes == 0) reloj.cancel();
      // Tic-tac en los últimos 5 segundos, para meter un poco de presión.
      if (segundosRestantes > 0 && segundosRestantes <= 5) efectos.tic();
      notifyListeners();
    });
    notifyListeners();
  }

  void _cerrarPregunta(ResultadoPregunta nuevo) {
    _reloj?.cancel();
    fase = FaseJuego.resultado;
    resultado = nuevo;
    respondieron = nuevo.respondieron;
    jugadoresEnPartida = nuevo.jugadores;
    ranking = nuevo.ranking;
    segundosRestantes = 0;
    if (!soyAnfitrion && miRespuestaId == nuevo.opcionCorrectaId) {
      efectos.acerto();
    } else if (!soyAnfitrion) {
      efectos.fallo();
    }
    notifyListeners();
  }

  /// Nos suscribimos al canal de la sala. Cada vez que Laravel
  /// emite JugadorSeUnio, Reverb nos lo entrega y agregamos al jugador.
  Future<void> _escucharSala() async {
    final codigo = sala!.codigo;
    _dejarDeEscuchar?.call();
    // Mientras estemos en una sala, el celular no se bloquea solo.
    efectos.pantallaPrendida(true);
    // Cada evento que emite Laravel cambia lo que se ve en pantalla.
    bool esEstaSala() => sala?.codigo == codigo;
    _dejarDeEscuchar = realtime.escucharSala(
      codigo,
      EventosSala(
        alUnirseJugador: (jugador) {
          if (!esEstaSala()) return;
          sala = sala!.conJugador(jugador);
          notifyListeners();
        },
        alMostrarPregunta: (nueva) {
          if (esEstaSala()) _mostrarPregunta(nueva);
        },
        alRecibirRespuesta: (cuantos, de) {
          if (!esEstaSala()) return;
          respondieron = cuantos;
          jugadoresEnPartida = de;
          notifyListeners();
        },
        alCerrarPregunta: (nuevo) {
          if (esEstaSala()) _cerrarPregunta(nuevo);
        },
        alTerminarPartida: (rankingFinal) {
          if (!esEstaSala()) return;
          _reloj?.cancel();
          ranking = rankingFinal;
          fase = FaseJuego.terminada;
          efectos.fin();
          efectos.pantallaPrendida(false);
          notifyListeners();
        },
      ),
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
    efectos.pantallaPrendida(false);
    _reloj?.cancel();
    _dejarDeEscuchar?.call();
    _estados?.cancel();
    super.dispose();
  }
}
