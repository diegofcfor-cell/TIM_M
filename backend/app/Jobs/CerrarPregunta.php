<?php

namespace App\Jobs;

use App\Models\RoomQuestion;
use App\Services\GameService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

/**
 * Trabajo en segundo plano: espera 30 o 60 segundos y cierra la pregunta.
 *
 * Para que funcione tiene que estar corriendo: php artisan queue:work
 */
class CerrarPregunta implements ShouldQueue
{
    use Queueable;

    public function __construct(public RoomQuestion $roomQuestion) {}

    public function handle(GameService $game): void
    {
        $game->closeQuestion($this->roomQuestion);
    }
}
