import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:laravel_reverb/laravel_reverb.dart';

import '../services/api_service.dart';
import '../services/realtime_service.dart';

/// Estado de la pantalla de prueba. Con Provider, cada vez que llamamos
/// a notifyListeners() la pantalla se vuelve a dibujar con los datos nuevos.
class PruebaConexion extends ChangeNotifier {
  PruebaConexion({required this.api, required this.realtime});

  final ApiService api;
  final RealtimeService realtime;

  String respuestaHttp = 'Todavía no probaste la API';
  ReverbState estadoWebSocket = ReverbState.disconnected;
  final List<String> mensajesRecibidos = [];

  StreamSubscription<ReverbState>? _estados;
  Cancelar? _cancelarCanal;

  Future<void> iniciar() async {
    _estados = realtime.estados.listen((estado) {
      estadoWebSocket = estado;
      notifyListeners();
    });
    _cancelarCanal = realtime.escucharPruebas((datos) {
      mensajesRecibidos.insert(0, '${datos['mensaje']} (${datos['hora']})');
      notifyListeners();
    });
    try {
      await realtime.conectar();
    } catch (_) {
      // El estado "failed" ya llega por el stream de estados.
    }
  }

  Future<void> probarHttp() async {
    respuestaHttp = 'Preguntando...';
    notifyListeners();
    try {
      final datos = await api.ping();
      respuestaHttp = '${datos['mensaje']}\n${datos['hora']}';
    } catch (error) {
      respuestaHttp = 'No se pudo conectar: $error';
    }
    notifyListeners();
  }

  Future<void> enviarATodos(String mensaje) async {
    try {
      await api.enviarATodos(mensaje);
    } catch (error) {
      mensajesRecibidos.insert(0, 'Error al enviar: $error');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _cancelarCanal?.call();
    _estados?.cancel();
    super.dispose();
  }
}
