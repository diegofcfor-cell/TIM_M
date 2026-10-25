<?php

namespace App\Support;

use App\Models\RoomQuestion;
use Carbon\CarbonInterface;

/**
 * Cuántos puntos vale una respuesta.
 *
 * Acertar da 500 puntos fijos, más un premio de hasta 500 por rapidez:
 * si respondés apenas aparece la pregunta te llevás casi 1000, y si
 * respondés en el último segundo, cerca de 500. Equivocarse da 0.
 */
class Puntos
{
    public const BASE = 500;

    public const PREMIO_RAPIDEZ = 500;

    public static function calcular(bool $correcta, RoomQuestion $roomQuestion, CarbonInterface $momento): int
    {
        if (! $correcta) {
            return 0;
        }

        $total = $roomQuestion->started_at->diffInMilliseconds($roomQuestion->ends_at);
        $restante = max(0, $momento->diffInMilliseconds($roomQuestion->ends_at, false));
        $fraccion = $total > 0 ? min(1, $restante / $total) : 0;

        return self::BASE + (int) round(self::PREMIO_RAPIDEZ * $fraccion);
    }
}
