# TriviaLive

Juego de preguntas en vivo para celulares y tablets Android. Sirve como ejemplo para un video que explica la comunicación en tiempo real con **Laravel 12**, **Laravel Reverb** y **WebSockets**.

El anfitrión crea una sala y elige el tema (matemáticas, ciencias naturales, ciencias sociales, música, etc.). Los jugadores entran desde la app, tienen 30 o 60 segundos por pregunta y van sumando puntos en vivo.

## Cómo está organizado

| Carpeta | Qué es | Lenguaje |
| --- | --- | --- |
| `backend/` | API en Laravel 12 + servidor de WebSockets Reverb. Acá viven las reglas, las preguntas y los puntos. | PHP |
| `app/` | App en Flutter para Android. Muestra las pantallas y escucha los avisos de Reverb. | Dart |

La idea clave: **la app le habla a Laravel por HTTP** (pide datos, manda respuestas) y **Laravel le avisa a todas las apps por WebSocket** a través de Reverb.

## Estado actual: fase 8 (lista para grabar)

- **Un solo comando** levanta la API, Reverb y la cola: `levantar.sh` (Linux/Mac) o `levantar.bat` (Windows, con doble clic). Además te muestra la IP de tu compu.
- **La IP del servidor se cambia desde la app** (ícono de arriba a la derecha → "Servidor"). Así el mismo `.apk` sirve en cualquier red Wi-Fi.
- **El `.apk` puede hablar por `http://`** con tu compu (Android lo bloquea si no se lo permitís).
- Fases anteriores: la app pulida (ícono, sonidos, vibración), puntos y podio, el juego con reloj, la sala en vivo, el login, las salas con QR, las 120 preguntas y la prueba de conexión.

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

Después levantá todo con un solo comando, dentro de `backend/`:

```bash
./levantar.sh        # Linux o Mac (Ctrl+C apaga todo)
levantar.bat         # Windows (o doble clic en el archivo)
```

O, si preferís verlo por partes, abrí **tres terminales** dentro de `backend/`:

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

### 3. Jugar con amigos (y grabar el video)

1. Conectá tu compu y todos los celulares a **la misma red Wi-Fi**.
2. En `backend/`, corré `./levantar.sh` (o `levantar.bat`). Anotá la IP que muestra, por ejemplo `192.168.1.20`.
3. Generá el instalador de la app (una sola vez):

   ```bash
   cd app
   flutter build apk --release
   ```

   El archivo queda en `app/build/app/outputs/flutter-apk/app-release.apk`.
4. Pasá ese `.apk` a cada celular (por cable, WhatsApp o Drive) e instalalo. Android va a pedir permiso para "instalar apps desconocidas": aceptá.
5. En cada celular abrí TriviaLive, tocá el ícono de arriba a la derecha, escribí la IP en **Servidor**, tocá **Guardar servidor** y volvé a abrir la app.
6. Probá los dos botones de esa pantalla. Si los dos andan, ¡a jugar!

Si tenés un celular conectado por cable, también podés instalarla directo con `flutter install`.

### 4. Publicarlo en internet (Render)

El juego entra en un solo servicio de [Render](https://render.com): un contenedor de Docker donde corren juntos Laravel, Reverb y la cola, detrás de nginx (que recibe todo por un solo puerto). La receta está en `render.yaml` y en `backend/Dockerfile`.

1. En Render: **New → Blueprint**, elegí este repositorio y aceptá. Te va a pedir `ANFITRION_PASSWORD`: inventá la contraseña del anfitrión.
2. Esperá a que termine el primer deploy (unos minutos). Te queda una dirección como `trivia-live.onrender.com`.
3. En cada celular: ícono de arriba a la derecha → **Servidor** → escribí `trivia-live.onrender.com` (sin `https://`) → Guardar → volvé a abrir la app. Con un nombre de internet la app usa sola `https://` y `wss://`.
4. Entrá como anfitrión con `anfitrion@trivia.test` y la contraseña que elegiste.

Cosas a saber del plan gratis:

- Se **duerme a los 15 minutos** sin uso y tarda cerca de un minuto en despertar. Abrí la prueba de conexión un rato antes de jugar.
- La base de datos es SQLite **dentro del contenedor**: cuando se duerme o se reinicia, se borran las salas (las preguntas y el anfitrión se cargan de nuevo solos).
- Para el día de la grabación podés pasarlo al plan de USD 7 por mes (no se duerme; se cobra por segundo) y después volverlo a gratis.

### 5. Tests

```bash
cd backend && php artisan test
cd app && flutter test
```

## Si algo no conecta

- **"No se pudo conectar" en la API**: revisá que `php artisan serve` esté corriendo con `--host=0.0.0.0` y que el celular esté en la misma red Wi-Fi.
- **El punto de Reverb queda en rojo**: revisá que `php artisan reverb:start` esté corriendo y que `REVERB_APP_KEY` en `backend/.env` sea igual a la de `app/lib/config.dart` (`trivia-live-key`).
- **La pregunta no se cierra sola al terminar el tiempo**: falta la terminal 3, `php artisan queue:work`.
- **Firewall de Windows**: la primera vez puede pedir permiso para PHP. Aceptá en "redes privadas".
