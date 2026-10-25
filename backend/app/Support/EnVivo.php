<?php

namespace App\Support;

use Throwable;

/**
 * Envía un evento por Reverb sin romper el pedido HTTP si Reverb no anda.
 *
 * Si falla, el error queda en storage/logs/laravel.log y la API sigue.
 */
class EnVivo
{
    public static function emitir(object $evento): void
    {
        try {
            event($evento);
        } catch (Throwable $e) {
            report($e);
        }
    }
}
