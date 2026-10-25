<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Room;
use App\Services\GameService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GameController extends Controller
{
    public function __construct(private GameService $game) {}

    /**
     * POST /api/rooms/{code}/start: solo el anfitrión de la sala.
     */
    public function start(Request $request, Room $room): JsonResponse
    {
        $this->ensureHost($request, $room);
        $this->game->start($room);

        return response()->json(['status' => $room->fresh()->status]);
    }

    /**
     * POST /api/rooms/{code}/next: siguiente pregunta o fin de la partida.
     */
    public function next(Request $request, Room $room): JsonResponse
    {
        $this->ensureHost($request, $room);
        $this->game->next($room);

        return response()->json(['status' => $room->fresh()->status]);
    }

    /**
     * POST /api/rooms/{code}/answer: el jugador manda su respuesta.
     * Se identifica con el encabezado X-Player-Token.
     */
    public function answer(Request $request, Room $room): JsonResponse
    {
        $data = $request->validate(['option_id' => ['required', 'integer']]);

        $player = $room->players()
            ->where('token', (string) $request->header('X-Player-Token'))
            ->first();
        abort_if(! $player, 401, 'No sos jugador de esta sala.');

        $this->game->answer($room, $player, $data['option_id']);

        // No decimos si acertó: eso se revela cuando se cierra la pregunta.
        return response()->json(['received' => true], 201);
    }

    private function ensureHost(Request $request, Room $room): void
    {
        abort_if($request->user()->id !== $room->host_id, 403, 'Solo el anfitrión puede hacer esto.');
    }
}
