import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:laravel_reverb/laravel_reverb.dart';
import 'package:provider/provider.dart';
import 'package:trivia_live/services/almacenamiento.dart';
import 'package:trivia_live/services/api_service.dart';
import 'package:trivia_live/services/realtime_service.dart';
import 'package:trivia_live/state/sala_actual.dart';

/// Ayudantes que comparten los tests de salas y de juego.

Map<String, dynamic> salaJson({
  List<Map<String, dynamic>> jugadores = const [],
}) => {
  'code': 'KX7P2A',
  'status': 'waiting',
  'seconds_per_question': 30,
  'total_questions': 10,
  'topic': {
    'id': 1,
    'name': 'Música',
    'slug': 'musica',
    'icon': 'music_note',
    'color': '#8E24AA',
  },
  'host': 'Profe',
  'players': jugadores,
};

http.Response json(Object cuerpo, int estado) => http.Response(
  jsonEncode(cuerpo),
  estado,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// Un Reverb "de mentira": no abre ningún WebSocket y nos deja simular
/// los eventos que manda Laravel (JugadorSeUnio, PreguntaMostrada, etc.).
class ReverbFalso extends RealtimeService {
  final _estados = StreamController<ReverbState>.broadcast();
  final canales = <String, EventosSala>{};

  @override
  Stream<ReverbState> get estados => _estados.stream;

  @override
  ReverbState get estado => ReverbState.connected;

  @override
  Future<void> conectar() async {}

  @override
  Cancelar escucharSala(String codigo, EventosSala eventos) {
    canales['sala.$codigo'] = eventos;
    return () => canales.remove('sala.$codigo');
  }
}

Widget app(MockClient laravel, Widget pantalla, {RealtimeService? realtime}) =>
    ChangeNotifierProvider(
      create: (_) => SalaActual(
        api: ApiService(client: laravel),
        almacenamiento: Almacenamiento(),
        realtime: realtime ?? ReverbFalso(),
      ),
      child: MaterialApp(home: pantalla),
    );
