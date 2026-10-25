<?php

namespace App\Events;

use App\Models\RoomQuestion;
use Illuminate\Broadcasting\Channel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;

/**
 * Arranca una pregunta: viaja a todos al mismo tiempo.
 *
 * Importante: NO dice cuál es la opción correcta. Si la mandáramos,
 * cualquiera podría verla espiando los mensajes del WebSocket.
 */
class PreguntaMostrada implements ShouldBroadcastNow
{
    public function __construct(public RoomQuestion $roomQuestion) {}

    public function broadcastOn(): Channel
    {
        return new Channel('sala.'.$this->roomQuestion->room->code);
    }

    public function broadcastWith(): array
    {
        $question = $this->roomQuestion->question;

        return [
            'position' => $this->roomQuestion->position,
            'total_questions' => $this->roomQuestion->room->total_questions,
            'text' => $question->text,
            'options' => $question->options
                ->map(fn ($option) => ['id' => $option->id, 'text' => $option->text])
                ->values()
                ->all(),
            // La app cuenta hacia atrás desde que recibe el evento.
            'seconds' => $this->roomQuestion->room->seconds_per_question,
            'ends_at' => $this->roomQuestion->ends_at->toIso8601String(),
        ];
    }
}
