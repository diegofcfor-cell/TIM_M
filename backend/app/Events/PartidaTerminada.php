<?php

namespace App\Events;

use App\Models\Room;
use Illuminate\Broadcasting\Channel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;

/**
 * Se terminaron las preguntas: manda el ranking final para armar el podio.
 */
class PartidaTerminada implements ShouldBroadcastNow
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
            'ranking' => $this->room->ranking(),
        ];
    }
}
