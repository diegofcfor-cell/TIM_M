<?php

namespace App\Events;

use App\Models\Room;
use Illuminate\Broadcasting\Channel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;

/**
 * El anfitrión tocó "Empezar": todas las apps pasan a modo juego.
 */
class PartidaIniciada implements ShouldBroadcastNow
{
    public function __construct(public Room $room) {}

    public function broadcastOn(): Channel
    {
        return new Channel('sala.'.$this->room->code);
    }

    public function broadcastWith(): array
    {
        return [
            'total_questions' => $this->room->total_questions,
            'seconds_per_question' => $this->room->seconds_per_question,
        ];
    }
}
