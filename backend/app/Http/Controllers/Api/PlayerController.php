<?php

namespace App\Http\Controllers\Api;

use App\Enums\RoomStatus;
use App\Events\JugadorSeUnio;
use App\Http\Controllers\Controller;
use App\Http\Requests\JoinRoomRequest;
use App\Http\Resources\PlayerResource;
use App\Http\Resources\RoomResource;
use App\Models\Room;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Str;
use Throwable;

class PlayerController extends Controller
{
    /**
     * POST /api/rooms/{code}/join: un jugador entra con su apodo, sin cuenta.
     *
     * Devuelve un token secreto que la app guarda en el celular. Más adelante
     * lo usa para mandar sus respuestas y para volver si se le cierra la app.
     */
    public function store(JoinRoomRequest $request, Room $room): JsonResponse
    {
        if ($room->status !== RoomStatus::Waiting) {
            return response()->json([
                'message' => 'La partida ya empezó. Esperá a la próxima.',
            ], 409);
        }

        $token = Str::random(64);
        $player = $room->players()->create([
            'nickname' => $request->validated('nickname'),
            'token' => $token,
        ]);

        // Avisamos por WebSocket a todos los que están en la sala. Si Reverb
        // no está andando, el jugador entra igual: solo se pierde el aviso.
        try {
            JugadorSeUnio::dispatch($player);
        } catch (Throwable $e) {
            report($e);
        }

        return response()->json([
            'player' => new PlayerResource($player),
            'token' => $token,
            'room' => new RoomResource($room->load('topic', 'host', 'players')),
        ], 201);
    }
}
