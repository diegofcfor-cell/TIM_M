import 'package:shared_preferences/shared_preferences.dart';

/// Configuración de conexión con el backend Laravel.
///
/// El servidor se puede elegir de dos formas, sin tocar el código:
///   1. Al compilar: flutter run --dart-define=HOST=192.168.1.20
///   2. Dentro de la app: en la pantalla "Prueba de conexión" (ícono de
///      arriba a la derecha). Así un mismo .apk sirve en cualquier red Wi-Fi.
///
/// - Emulador de Android: 10.0.2.2 (es "localhost" de tu computadora).
/// - Celular o tablet real: la IP de tu computadora en la red Wi-Fi.
class Config {
  static const hostPorDefecto = String.fromEnvironment(
    'HOST',
    defaultValue: '10.0.2.2',
  );

  /// La IP o el nombre del servidor que se usa ahora.
  static String host = hostPorDefecto;

  static const _claveHost = 'servidor';

  /// Lee el servidor que se eligió dentro de la app (si se eligió alguno).
  /// Se llama una sola vez, al arrancar.
  static Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    host = prefs.getString(_claveHost) ?? hostPorDefecto;
  }

  /// Guarda otro servidor. Se usa la próxima vez que se abra la app,
  /// porque la conexión con Reverb se arma una sola vez al arrancar.
  static Future<void> guardarHost(String nuevo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveHost, nuevo.trim());
  }

  /// Una IP (192.168.1.20) o un nombre (trivia.ejemplo.com), sin http://
  /// ni puerto.
  static bool hostValido(String texto) =>
      RegExp(r'^[a-zA-Z0-9.-]+$').hasMatch(texto.trim());

  /// Puerto de `php artisan serve` (la API por HTTP).
  static const apiPort = int.fromEnvironment('API_PORT', defaultValue: 8000);

  /// Puerto de `php artisan reverb:start` (los WebSockets).
  static const reverbPort = int.fromEnvironment(
    'REVERB_PORT',
    defaultValue: 8080,
  );

  /// Tiene que ser igual a REVERB_APP_KEY del archivo backend/.env.
  static const reverbAppKey = String.fromEnvironment(
    'REVERB_APP_KEY',
    defaultValue: 'trivia-live-key',
  );

  static String get apiBaseUrl => 'http://$host:$apiPort/api';
}
