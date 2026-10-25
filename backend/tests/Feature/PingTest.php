<?php

namespace Tests\Feature;

use App\Events\PingEnviado;
use Illuminate\Support\Facades\Event;
use Tests\TestCase;

class PingTest extends TestCase
{
    public function test_ping_responde_con_json(): void
    {
        $this->getJson('/api/ping')
            ->assertOk()
            ->assertJsonPath('mensaje', '¡Hola desde Laravel 12!')
            ->assertJsonStructure(['mensaje', 'hora']);
    }

    public function test_broadcast_emite_el_evento_en_el_canal_pruebas(): void
    {
        Event::fake([PingEnviado::class]);

        $this->postJson('/api/ping/broadcast', ['mensaje' => 'Hola sala'])
            ->assertStatus(202)
            ->assertJsonPath('enviado', true);

        Event::assertDispatched(
            PingEnviado::class,
            fn (PingEnviado $evento) => $evento->mensaje === 'Hola sala'
                && $evento->broadcastOn()->name === 'pruebas'
        );
    }

    public function test_broadcast_exige_un_mensaje(): void
    {
        $this->postJson('/api/ping/broadcast', [])
            ->assertStatus(422)
            ->assertJsonValidationErrors('mensaje');
    }
}
