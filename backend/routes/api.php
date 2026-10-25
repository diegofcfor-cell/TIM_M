<?php

use App\Events\PingEnviado;
use App\Http\Controllers\Api\TopicController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

// Fase 1: prueba por HTTP. La app pide y Laravel responde con JSON.
Route::get('/ping', function () {
    return response()->json([
        'mensaje' => '¡Hola desde Laravel 12!',
        'hora' => now()->toIso8601String(),
    ]);
});

// Fase 1: prueba de tiempo real. La app pide por HTTP y Laravel
// avisa por WebSocket (Reverb) a todas las apps conectadas.
Route::post('/ping/broadcast', function (Request $request) {
    $datos = $request->validate([
        'mensaje' => ['required', 'string', 'max:100'],
    ]);

    $hora = now()->toIso8601String();

    PingEnviado::dispatch($datos['mensaje'], $hora);

    return response()->json(['enviado' => true, 'hora' => $hora], 202);
});

// Fase 2: los temas del juego, con cuántas preguntas tiene cada uno.
Route::get('/topics', [TopicController::class, 'index']);
