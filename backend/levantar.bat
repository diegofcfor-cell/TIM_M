@echo off
rem Levanta todo lo que necesita el juego con un doble clic (Windows).
rem Abre 3 ventanas: la API, los WebSockets y la cola. Para apagar, cerralas.
cd /d "%~dp0"
echo Escribi esta IP en la app (Prueba de conexion - Servidor):
ipconfig | findstr /c:"IPv4"
echo.
start "TriviaLive - API" php artisan serve --host=0.0.0.0 --port=8000
start "TriviaLive - Reverb" php artisan reverb:start --host=0.0.0.0 --port=8080
start "TriviaLive - Cola" php artisan queue:work
pause
