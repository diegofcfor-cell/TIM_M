import 'package:flutter/foundation.dart';

import '../services/almacenamiento.dart';
import '../services/api_service.dart';

/// La sesión del anfitrión: si inició sesión y con qué nombre.
class Sesion extends ChangeNotifier {
  Sesion({required this.api, required this.almacenamiento});

  final ApiService api;
  final Almacenamiento almacenamiento;

  String? nombre;

  bool get iniciada => api.tokenAnfitrion != null;

  /// Al abrir la app, recupera la sesión guardada en el celular.
  Future<void> cargarGuardada() async {
    final guardada = await almacenamiento.leerAnfitrion();
    if (guardada == null) return;
    api.tokenAnfitrion = guardada.token;
    nombre = guardada.nombre;
    notifyListeners();
  }

  Future<void> iniciar(String email, String password) async {
    final datos = await api.login(email, password);
    api.tokenAnfitrion = datos.token;
    nombre = datos.nombre;
    await almacenamiento.guardarAnfitrion(datos.token, datos.nombre);
    notifyListeners();
  }

  Future<void> cerrar() async {
    api.tokenAnfitrion = null;
    nombre = null;
    await almacenamiento.borrarAnfitrion();
    notifyListeners();
  }
}
