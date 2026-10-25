import 'package:flutter/foundation.dart';

import '../models/tema.dart';
import '../services/api_service.dart';

/// Estado de la lista de temas: cargando, con error o con los datos.
class Temas extends ChangeNotifier {
  Temas({required this.api});

  final ApiService api;

  List<Tema> lista = [];
  bool cargando = false;
  String? error;

  Future<void> cargar() async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      lista = await api.temas();
    } catch (e) {
      error = 'No se pudieron cargar los temas: $e';
    }
    cargando = false;
    notifyListeners();
  }
}
