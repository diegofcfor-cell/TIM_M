# TriviaLive

Juego de preguntas en vivo para celulares y tablets Android. Sirve como ejemplo para un video que explica la comunicación en tiempo real con **Laravel 12**, **Laravel Reverb** y **WebSockets**.

El anfitrión crea una sala y elige el tema (matemáticas, ciencias naturales, ciencias sociales, música, etc.). Los jugadores entran desde la app, tienen 30 o 60 segundos por pregunta y van sumando puntos en vivo.

## Cómo está organizado

| Carpeta | Qué es | Lenguaje |
| --- | --- | --- |
| `backend/` | API en Laravel 12 + servidor de WebSockets Reverb. Acá viven las reglas, las preguntas y los puntos. | PHP |
| `app/` | App en Flutter para Android. Muestra las pantallas y escucha los avisos de Reverb. | Dart |

La idea clave: **la app le habla a Laravel por HTTP** (pide datos, manda respuestas) y **Laravel le avisa a todas las apps por WebSocket** a través de Reverb.

## Estado actual: fase 6 (puntos, ranking y podio)

- **Cómo se ganan puntos:** acertar da **500 puntos**, más un **premio por rapidez de hasta 500**. Si respondés apenas aparece la pregunta te llevás casi 1000; si respondés en el último segundo, unos 500. Equivocarse da 0.
- **Laravel calcula los puntos** con su propio reloj, así nadie puede hacer trampa desde el celular.
- **Después de cada pregunta** (evento `PreguntaCerrada`) llega el ranking: el jugador ve "¡Correcto! +850 puntos" y en qué puesto va, y el anfitrión ve los 5 primeros.
- **Al final** (evento `PartidaTerminada`) todos ven el **podio** con el 1°, 2° y 3°, y el resto de la lista. Si dos empatan, comparten el puesto.
- Fases anteriores: el juego con preguntas y reloj, la sala de espera en vivo, login del anfitrión, crear sala con código y QR, unirse con apodo, 120 preguntas en 6 temas y la prueba de conexión.

Para jugar tienen que estar corriendo **las tres terminales**: `php artisan serve`, `php artisan reverb:start` y `php artisan queue:work`.

## Requisitos

- PHP 8.2 o superior y [Composer](https://getcomposer.org)
- [Flutter](https://docs.flutter.dev/get-started/install) (incluye Dart)
- Android Studio con un emulador, o un celular Android con la depuración USB activada

## Cómo ejecutarlo

### 1. Backend (Laravel + Reverb)

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
```

`--seed` carga los temas, las preguntas y un anfitrión de prueba (`anfitrion@trivia.test`, contraseña `password`).

Después abrí **tres terminales** dentro de `backend/`:

```bash
# Terminal 1: la API por HTTP
php artisan serve --host=0.0.0.0 --port=8000

# Terminal 2: el servidor de WebSockets
php artisan reverb:start --host=0.0.0.0 --port=8080

# Terminal 3: la cola, que cierra cada pregunta cuando se acaba el tiempo
php artisan queue:work
```

`--host=0.0.0.0` hace que tu computadora acepte conexiones de otros dispositivos de la red Wi-Fi, como tu celular.

### 2. App (Flutter)

```bash
cd app
flutter pub get

# Con el emulador de Android (10.0.2.2 es "tu computadora" vista desde el emulador):
flutter run

# Con un celular real en la misma red Wi-Fi (poné la IP de tu computadora):
flutter run --dart-define=HOST=192.168.1.20
```

Para saber la IP de tu computadora: `ipconfig` en Windows o `ip addr` en Linux.

### 3. Tests

```bash
cd backend && php artisan test
cd app && flutter test
```

## Si algo no conecta

- **"No se pudo conectar" en la API**: revisá que `php artisan serve` esté corriendo con `--host=0.0.0.0` y que el celular esté en la misma red Wi-Fi.
- **El punto de Reverb queda en rojo**: revisá que `php artisan reverb:start` esté corriendo y que `REVERB_APP_KEY` en `backend/.env` sea igual a la de `app/lib/config.dart` (`trivia-live-key`).
- **La pregunta no se cierra sola al terminar el tiempo**: falta la terminal 3, `php artisan queue:work`.
- **Firewall de Windows**: la primera vez puede pedir permiso para PHP. Aceptá en "redes privadas".
