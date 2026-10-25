<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * Evento de prueba de la fase 1.
 *
 * Laravel lo envía a Reverb y Reverb lo reparte a todas las apps
 * que escuchan el canal público "pruebas". Usa ShouldBroadcastNow
 * para enviarse en el momento, sin pasar por la cola de trabajos.
 */
class PingEnviado implements ShouldBroadcastNow
{
    use Dispatchable;

    public function __construct(
        public string $mensaje,
        public string $hora,
    ) {}

    public function broadcastOn(): Channel
    {
        return new Channel('pruebas');
    }
}
