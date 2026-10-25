/// Configuración de conexión con el backend Laravel.
///
/// Se puede cambiar al ejecutar la app, sin tocar el código:
///   flutter run --dart-define=HOST=192.168.1.20
///
/// - Emulador de Android: 10.0.2.2 (es "localhost" de tu computadora).
/// - Celular o tablet real: la IP de tu computadora en la red Wi-Fi.
class Config {
  static const host = String.fromEnvironment('HOST', defaultValue: '10.0.2.2');

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
