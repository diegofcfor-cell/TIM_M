/// Una de las 4 opciones. No sabemos cuál es la correcta hasta que
/// se cierra la pregunta: el servidor no lo manda antes.
class OpcionPregunta {
  const OpcionPregunta({required this.id, required this.texto});

  factory OpcionPregunta.fromJson(Map<String, dynamic> json) {
    return OpcionPregunta(id: json['id'] as int, texto: json['text'] as String);
  }

  final int id;
  final String texto;
}

/// Lo que llega con el evento PreguntaMostrada.
class Pregunta {
  const Pregunta({
    required this.posicion,
    required this.total,
    required this.texto,
    required this.opciones,
    required this.segundos,
  });

  factory Pregunta.fromJson(Map<String, dynamic> json) {
    return Pregunta(
      posicion: json['position'] as int,
      total: json['total_questions'] as int,
      texto: json['text'] as String,
      opciones: (json['options'] as List<dynamic>)
          .map((o) => OpcionPregunta.fromJson(o as Map<String, dynamic>))
          .toList(),
      segundos: json['seconds'] as int,
    );
  }

  final int posicion;
  final int total;
  final String texto;
  final List<OpcionPregunta> opciones;
  final int segundos;
}

/// Una fila del ranking: quién va en qué puesto y con cuántos puntos.
class PuestoRanking {
  const PuestoRanking({
    required this.posicion,
    required this.jugadorId,
    required this.apodo,
    required this.puntos,
    this.puntosPregunta = 0,
  });

  factory PuestoRanking.fromJson(Map<String, dynamic> json) {
    return PuestoRanking(
      posicion: json['position'] as int,
      jugadorId: json['id'] as int,
      apodo: json['nickname'] as String,
      puntos: json['score'] as int,
      puntosPregunta: json['points'] as int? ?? 0,
    );
  }

  /// Si hay empate, dos jugadores comparten el mismo puesto.
  final int posicion;
  final int jugadorId;
  final String apodo;

  /// Puntos totales en la partida.
  final int puntos;

  /// Puntos que sumó en la última pregunta (el "+850").
  final int puntosPregunta;

  static List<PuestoRanking> listaDesdeJson(List<dynamic> json) => json
      .map((p) => PuestoRanking.fromJson(p as Map<String, dynamic>))
      .toList();
}

/// Lo que llega con el evento PreguntaCerrada.
class ResultadoPregunta {
  const ResultadoPregunta({
    required this.posicion,
    required this.opcionCorrectaId,
    required this.respondieron,
    required this.acertaron,
    required this.jugadores,
    required this.esUltima,
    this.ranking = const [],
  });

  factory ResultadoPregunta.fromJson(Map<String, dynamic> json) {
    return ResultadoPregunta(
      posicion: json['position'] as int,
      opcionCorrectaId: json['correct_option_id'] as int,
      respondieron: json['answered'] as int,
      acertaron: json['correct'] as int,
      jugadores: json['players'] as int,
      esUltima: json['is_last'] as bool,
      ranking: PuestoRanking.listaDesdeJson(
        json['ranking'] as List<dynamic>? ?? const [],
      ),
    );
  }

  final int posicion;
  final int opcionCorrectaId;
  final int respondieron;
  final int acertaron;
  final int jugadores;
  final bool esUltima;
  final List<PuestoRanking> ranking;
}
