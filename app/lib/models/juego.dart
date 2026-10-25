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

/// Lo que llega con el evento PreguntaCerrada.
class ResultadoPregunta {
  const ResultadoPregunta({
    required this.posicion,
    required this.opcionCorrectaId,
    required this.respondieron,
    required this.acertaron,
    required this.jugadores,
    required this.esUltima,
  });

  factory ResultadoPregunta.fromJson(Map<String, dynamic> json) {
    return ResultadoPregunta(
      posicion: json['position'] as int,
      opcionCorrectaId: json['correct_option_id'] as int,
      respondieron: json['answered'] as int,
      acertaron: json['correct'] as int,
      jugadores: json['players'] as int,
      esUltima: json['is_last'] as bool,
    );
  }

  final int posicion;
  final int opcionCorrectaId;
  final int respondieron;
  final int acertaron;
  final int jugadores;
  final bool esUltima;
}
