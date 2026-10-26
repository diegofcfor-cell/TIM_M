#!/usr/bin/env bash
# Levanta todo lo que necesita el juego con un solo comando (Linux y Mac):
#   1. la API por HTTP          (php artisan serve)
#   2. los WebSockets            (php artisan reverb:start)
#   3. la cola que cierra preguntas (php artisan queue:work)
# Para apagar todo: Ctrl+C.
cd "$(dirname "$0")"

echo "Escribí esta IP en la app (Prueba de conexión → Servidor):"
if command -v ipconfig >/dev/null 2>&1 && [ "$(uname)" = "Darwin" ]; then
  ipconfig getifaddr en0 || ipconfig getifaddr en1
else
  hostname -I | awk '{print $1}'
fi
echo

# Al apretar Ctrl+C (o al cerrar la terminal) se apagan los tres.
trap 'trap - INT TERM EXIT; kill 0' INT TERM EXIT

php artisan serve --host=0.0.0.0 --port=8000 &
php artisan reverb:start --host=0.0.0.0 --port=8080 &
php artisan queue:work &
wait
