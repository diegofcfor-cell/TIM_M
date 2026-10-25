<?php

namespace App\Enums;

/**
 * Los estados por los que pasa una sala durante la partida:
 * waiting → playing → showing_results → playing → ... → finished
 */
enum RoomStatus: string
{
    case Waiting = 'waiting';
    case Playing = 'playing';
    case ShowingResults = 'showing_results';
    case Finished = 'finished';
}
