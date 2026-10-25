import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/sala.dart';
import '../models/tema.dart';

/// Un error que Laravel explicó con un mensaje para mostrar en pantalla.
class ApiException implements Exception {
  ApiException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Habla con Laravel por HTTP: la app pide y Laravel responde con JSON.
class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Token del anfitrión (Sanctum). Se manda en los pedidos que piden login.
  String? tokenAnfitrion;

  Future<Map<String, dynamic>> ping() => _get('/ping');

  /// Le pide a Laravel que avise a todas las apps por WebSocket.
  Future<Map<String, dynamic>> enviarATodos(String mensaje) =>
      _post('/ping/broadcast', {'mensaje': mensaje});

  /// Los temas que el anfitrión puede elegir para su sala.
  Future<List<Tema>> temas() async {
    final lista = (await _get('/topics'))['data'] as List<dynamic>;
    return lista
        .map((json) => Tema.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Inicia sesión y devuelve el token y el nombre del anfitrión.
  Future<({String token, String nombre})> login(
    String email,
    String password,
  ) async {
    final datos = await _post('/login', {'email': email, 'password': password});
    final usuario = datos['user'] as Map<String, dynamic>;
    return (token: datos['token'] as String, nombre: usuario['name'] as String);
  }

  Future<Sala> crearSala({
    required int temaId,
    required int segundos,
    required int cantidadPreguntas,
  }) async {
    final datos = await _post('/rooms', {
      'topic_id': temaId,
      'seconds_per_question': segundos,
      'total_questions': cantidadPreguntas,
    });
    return Sala.fromJson(datos['data'] as Map<String, dynamic>);
  }

  Future<Sala> verSala(String codigo) async {
    final datos = await _get('/rooms/$codigo');
    return Sala.fromJson(datos['data'] as Map<String, dynamic>);
  }

  /// Entra a la sala con un apodo. El token identifica al jugador.
  Future<({Sala sala, String token, int jugadorId})> unirse(
    String codigo,
    String apodo,
  ) async {
    final datos = await _post('/rooms/$codigo/join', {'nickname': apodo});
    final jugador = datos['player'] as Map<String, dynamic>;
    return (
      sala: Sala.fromJson(datos['room'] as Map<String, dynamic>),
      token: datos['token'] as String,
      jugadorId: jugador['id'] as int,
    );
  }

  Future<Map<String, dynamic>> _get(String ruta) async {
    final respuesta = await _client.get(_url(ruta), headers: _encabezados());
    return _leer(respuesta);
  }

  Future<Map<String, dynamic>> _post(
    String ruta,
    Map<String, dynamic> cuerpo,
  ) async {
    final respuesta = await _client.post(
      _url(ruta),
      headers: _encabezados(),
      body: jsonEncode(cuerpo),
    );
    return _leer(respuesta);
  }

  Uri _url(String ruta) => Uri.parse('${Config.apiBaseUrl}$ruta');

  Map<String, String> _encabezados() => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (tokenAnfitrion != null) 'Authorization': 'Bearer $tokenAnfitrion',
  };

  /// Convierte la respuesta en un Map, o en un ApiException con el mensaje
  /// que mandó Laravel (por ejemplo, "Ese apodo ya está en uso").
  Map<String, dynamic> _leer(http.Response respuesta) {
    final cuerpo = respuesta.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;

    if (respuesta.statusCode < 400) {
      return cuerpo;
    }
    final errores = cuerpo['errors'] as Map<String, dynamic>?;
    if (errores != null && errores.isNotEmpty) {
      throw ApiException(
        (errores.values.first as List<dynamic>).first as String,
      );
    }
    if (respuesta.statusCode == 404) {
      throw ApiException('No encontramos una sala con ese código.');
    }
    throw ApiException(
      cuerpo['message'] as String? ??
          'Laravel respondió con un error (${respuesta.statusCode}).',
    );
  }
}
