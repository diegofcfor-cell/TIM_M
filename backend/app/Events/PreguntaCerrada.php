<?php

namespace App\Events;

use App\Models\RoomQuestion;
use Illuminate\Broadcasting\Channel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;

/**
 * Se terminó el tiempo (o respondieron todos): ahora sí se revela
 * la opción correcta.
 */
class PreguntaCerrada implements ShouldBroadcastNow
{
    public function __construct(public RoomQuestion $roomQuestion) {}

    public function broadcastOn(): Channel
    {
        return new Channel('sala.'.$this->roomQuestion->room->code);
    }

    public function broadcastWith(): array
    {
        $room = $this->roomQuestion->room;

        return [
            'position' => $this->roomQuestion->position,
            'correct_option_id' => $this->roomQuestion->question->correctOption->id,
            'answered' => $this->roomQuestion->answers()->count(),
            'correct' => $this->roomQuestion->answers()->where('is_correct', true)->count(),
            'players' => $room->players()->count(),
            'is_last' => $this->roomQuestion->position >= $room->total_questions,
        ];
    }
}
