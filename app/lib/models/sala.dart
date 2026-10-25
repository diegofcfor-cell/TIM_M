import 'tema.dart';

/// Un jugador de la sala, tal como lo manda Laravel (sin su token).
class Jugador {
  const Jugador({required this.id, required this.apodo, required this.puntos});

  factory Jugador.fromJson(Map<String, dynamic> json) {
    return Jugador(
      id: json['id'] as int,
      apodo: json['nickname'] as String,
      puntos: json['score'] as int,
    );
  }

  final int id;
  final String apodo;
  final int puntos;
}

/// Una sala de juego, tal como llega desde /api/rooms/{codigo}.
class Sala {
  const Sala({
    required this.codigo,
    required this.estado,
    required this.segundosPorPregunta,
    required this.totalPreguntas,
    required this.tema,
    required this.anfitrion,
    required this.jugadores,
  });

  factory Sala.fromJson(Map<String, dynamic> json) {
    return Sala(
      codigo: json['code'] as String,
      estado: json['status'] as String,
      segundosPorPregunta: json['seconds_per_question'] as int,
      totalPreguntas: json['total_questions'] as int,
      tema: Tema.fromJson(json['topic'] as Map<String, dynamic>),
      anfitrion: json['host'] as String,
      jugadores: (json['players'] as List<dynamic>)
          .map((j) => Jugador.fromJson(j as Map<String, dynamic>))
          .toList(),
    );
  }

  final String codigo;
  final String estado;
  final int segundosPorPregunta;
  final int totalPreguntas;
  final Tema tema;
  final String anfitrion;
  final List<Jugador> jugadores;

  /// Una copia de la sala con un jugador más (si no estaba ya en la lista).
  Sala conJugador(Jugador nuevo) {
    if (jugadores.any((j) => j.id == nuevo.id)) return this;
    return Sala(
      codigo: codigo,
      estado: estado,
      segundosPorPregunta: segundosPorPregunta,
      totalPreguntas: totalPreguntas,
      tema: tema,
      anfitrion: anfitrion,
      jugadores: [...jugadores, nuevo],
    );
  }

  /// Los códigos tienen 6 letras o números, sin O, 0, I ni 1.
  static final formatoCodigo = RegExp(r'^[A-HJ-NP-Z2-9]{6}$');
}
