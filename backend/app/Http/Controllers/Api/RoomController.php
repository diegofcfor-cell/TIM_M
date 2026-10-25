<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreRoomRequest;
use App\Http\Resources\RoomResource;
use App\Models\Room;
use App\Models\Topic;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class RoomController extends Controller
{
    /**
     * POST /api/rooms: el anfitrión crea una sala y se sortean las preguntas.
     */
    public function store(StoreRoomRequest $request): JsonResponse
    {
        $topic = Topic::findOrFail($request->integer('topic_id'));

        $room = DB::transaction(function () use ($request, $topic) {
            $room = $request->user()->rooms()->create([
                'code' => Room::generateUniqueCode(),
                'topic_id' => $topic->id,
                'seconds_per_question' => $request->integer('seconds_per_question'),
                'total_questions' => $request->totalQuestions(),
            ]);

            $questionIds = $topic->questions()
                ->inRandomOrder()
                ->limit($request->totalQuestions())
                ->pluck('id');

            foreach ($questionIds as $index => $questionId) {
                $room->roomQuestions()->create([
                    'question_id' => $questionId,
                    'position' => $index + 1,
                ]);
            }

            return $room;
        });

        return (new RoomResource($room->load('topic', 'host', 'players')))
            ->response()
            ->setStatusCode(201);
    }

    /**
     * GET /api/rooms/{code}: datos de la sala y la lista de jugadores.
     */
    public function show(Room $room): RoomResource
    {
        return new RoomResource($room->load('topic', 'host', 'players'));
    }
}
