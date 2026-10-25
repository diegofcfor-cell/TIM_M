import 'package:shared_preferences/shared_preferences.dart';

/// Guarda datos chicos en el celular para que sobrevivan si se cierra la app.
class Almacenamiento {
  static const _tokenAnfitrion = 'token_anfitrion';
  static const _nombreAnfitrion = 'nombre_anfitrion';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<({String token, String nombre})?> leerAnfitrion() async {
    final prefs = await _prefs;
    final token = prefs.getString(_tokenAnfitrion);
    final nombre = prefs.getString(_nombreAnfitrion);
    if (token == null || nombre == null) return null;
    return (token: token, nombre: nombre);
  }

  Future<void> guardarAnfitrion(String token, String nombre) async {
    final prefs = await _prefs;
    await prefs.setString(_tokenAnfitrion, token);
    await prefs.setString(_nombreAnfitrion, nombre);
  }

  Future<void> borrarAnfitrion() async {
    final prefs = await _prefs;
    await prefs.remove(_tokenAnfitrion);
    await prefs.remove(_nombreAnfitrion);
  }

  /// El token del jugador se guarda por sala: "token_jugador_KX7P2A".
  Future<void> guardarTokenJugador(String codigo, String token) async {
    await (await _prefs).setString('token_jugador_$codigo', token);
  }
}
