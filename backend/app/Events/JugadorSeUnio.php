<?php

namespace App\Events;

use App\Http\Resources\PlayerResource;
use App\Models\Player;
use Illuminate\Broadcasting\Channel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * Se emite cuando un jugador entra a una sala.
 *
 * Viaja por Reverb a todas las apps que escuchan el canal "sala.{codigo}",
 * así la lista de jugadores se actualiza sola en todas las pantallas.
 */
class JugadorSeUnio implements ShouldBroadcastNow
{
    use Dispatchable;

    public function __construct(public Player $player) {}

    public function broadcastOn(): Channel
    {
        return new Channel('sala.'.$this->player->room->code);
    }

    /**
     * Lo que recibe la app. Nunca incluye el token del jugador.
     */
    public function broadcastWith(): array
    {
        return [
            'player' => (new PlayerResource($this->player))->resolve(),
            'players_count' => $this->player->room->players()->count(),
        ];
    }
}
