import 'package:flutter/material.dart';

/// Un tema del juego, tal como llega desde GET /api/topics.
class Tema {
  const Tema({
    required this.id,
    required this.nombre,
    required this.slug,
    required this.icono,
    required this.color,
    required this.cantidadPreguntas,
  });

  /// Convierte el JSON de Laravel en un objeto de Dart.
  factory Tema.fromJson(Map<String, dynamic> json) {
    return Tema(
      id: json['id'] as int,
      nombre: json['name'] as String,
      slug: json['slug'] as String,
      icono: _iconos[json['icon']] ?? Icons.quiz,
      color: _colorDesdeHex(json['color'] as String),
      cantidadPreguntas: json['questions_count'] as int? ?? 0,
    );
  }

  final int id;
  final String nombre;
  final String slug;
  final IconData icono;
  final Color color;
  final int cantidadPreguntas;

  /// Laravel manda el nombre del ícono como texto; acá lo traducimos.
  static const _iconos = {
    'calculate': Icons.calculate,
    'science': Icons.science,
    'public': Icons.public,
    'music_note': Icons.music_note,
    'sports_soccer': Icons.sports_soccer,
    'movie': Icons.movie,
  };

  /// "#1E88E5" → Color(0xFF1E88E5)
  static Color _colorDesdeHex(String hex) {
    return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
  }
}
