<?php

namespace App\Events;

use App\Models\RoomQuestion;
use Illuminate\Broadcasting\Channel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;

/**
 * Alguien respondió. Solo cuenta cuántos: no dice quién ni qué eligió.
 */
class RespuestaRecibida implements ShouldBroadcastNow
{
    public function __construct(public RoomQuestion $roomQuestion) {}

    public function broadcastOn(): Channel
    {
        return new Channel('sala.'.$this->roomQuestion->room->code);
    }

    public function broadcastWith(): array
    {
        return [
            'answered' => $this->roomQuestion->answers()->count(),
            'players' => $this->roomQuestion->room->players()->count(),
        ];
    }
}
