import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/tema.dart';

/// Habla con Laravel por HTTP: la app pide y Laravel responde con JSON.
class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> ping() async {
    final respuesta = await _client.get(
      Uri.parse('${Config.apiBaseUrl}/ping'),
      headers: {'Accept': 'application/json'},
    );
    return _leer(respuesta);
  }

  /// Le pide a Laravel que avise a todas las apps por WebSocket.
  Future<Map<String, dynamic>> enviarATodos(String mensaje) async {
    final respuesta = await _client.post(
      Uri.parse('${Config.apiBaseUrl}/ping/broadcast'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'mensaje': mensaje}),
    );
    return _leer(respuesta);
  }

  /// Los temas que el anfitrión puede elegir para su sala.
  Future<List<Tema>> temas() async {
    final respuesta = await _client.get(
      Uri.parse('${Config.apiBaseUrl}/topics'),
      headers: {'Accept': 'application/json'},
    );
    final lista = _leer(respuesta)['data'] as List<dynamic>;
    return lista
        .map((json) => Tema.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> _leer(http.Response respuesta) {
    if (respuesta.statusCode >= 400) {
      throw Exception('Laravel respondió ${respuesta.statusCode}');
    }
    return jsonDecode(respuesta.body) as Map<String, dynamic>;
  }
}
