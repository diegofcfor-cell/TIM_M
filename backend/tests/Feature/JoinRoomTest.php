<?php

namespace Tests\Feature;

use App\Enums\RoomStatus;
use App\Events\JugadorSeUnio;
use App\Models\Room;
use App\Models\Topic;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Tests\TestCase;

class JoinRoomTest extends TestCase
{
    use RefreshDatabase;

    private Room $room;

    protected function setUp(): void
    {
        parent::setUp();

        $this->room = Room::create([
            'code' => 'KX7P2A',
            'host_id' => User::factory()->create()->id,
            'topic_id' => Topic::factory()->create()->id,
        ]);
    }

    public function test_un_jugador_entra_con_su_apodo_y_recibe_un_token(): void
    {
        $response = $this->postJson('/api/rooms/KX7P2A/join', ['nickname' => '  Diego  '])
            ->assertCreated()
            ->assertJsonPath('player.nickname', 'Diego')
            ->assertJsonPath('player.score', 0)
            ->assertJsonPath('room.players.0.nickname', 'Diego');

        $token = $response->json('token');
        $this->assertSame(64, strlen($token));
        $this->assertDatabaseHas('players', ['room_id' => $this->room->id, 'token' => $token]);
    }

    public function test_no_se_repiten_apodos_en_la_misma_sala(): void
    {
        $this->postJson('/api/rooms/KX7P2A/join', ['nickname' => 'Diego'])->assertCreated();

        $this->postJson('/api/rooms/KX7P2A/join', ['nickname' => 'Diego'])
            ->assertStatus(422)
            ->assertJsonPath('errors.nickname.0', 'Ese apodo ya está en uso en esta sala. Probá con otro.');
    }

    public function test_el_mismo_apodo_puede_estar_en_otra_sala(): void
    {
        Room::create(['code' => 'ABC234', 'host_id' => $this->room->host_id, 'topic_id' => $this->room->topic_id]);

        $this->postJson('/api/rooms/KX7P2A/join', ['nickname' => 'Diego'])->assertCreated();
        $this->postJson('/api/rooms/ABC234/join', ['nickname' => 'Diego'])->assertCreated();
    }

    public function test_hace_falta_un_apodo(): void
    {
        $this->postJson('/api/rooms/KX7P2A/join', ['nickname' => '   '])
            ->assertStatus(422)
            ->assertJsonPath('errors.nickname.0', 'Escribí un apodo para entrar.');
    }

    public function test_no_se_puede_entrar_si_la_partida_ya_empezo(): void
    {
        $this->room->update(['status' => RoomStatus::Playing]);

        $this->postJson('/api/rooms/KX7P2A/join', ['nickname' => 'Diego'])
            ->assertStatus(409)
            ->assertJsonPath('message', 'La partida ya empezó. Esperá a la próxima.');
    }

    public function test_al_entrar_se_avisa_por_websocket_en_el_canal_de_la_sala(): void
    {
        Event::fake([JugadorSeUnio::class]);

        $this->postJson('/api/rooms/KX7P2A/join', ['nickname' => 'Diego'])->assertCreated();

        Event::assertDispatched(JugadorSeUnio::class, function (JugadorSeUnio $evento) {
            $datos = $evento->broadcastWith();

            return $evento->broadcastOn()->name === 'sala.KX7P2A'
                && $datos['player']['nickname'] === 'Diego'
                && $datos['players_count'] === 1
                && ! array_key_exists('token', $datos['player']);
        });
    }

    public function test_si_reverb_no_anda_el_jugador_entra_igual(): void
    {
        // Apuntamos a un puerto donde no hay ningún servidor de WebSockets.
        config([
            'broadcasting.default' => 'reverb',
            'broadcasting.connections.reverb.key' => 'clave',
            'broadcasting.connections.reverb.secret' => 'secreto',
            'broadcasting.connections.reverb.app_id' => 'app',
            'broadcasting.connections.reverb.options.host' => '127.0.0.1',
            'broadcasting.connections.reverb.options.port' => 1,
            'broadcasting.connections.reverb.options.scheme' => 'http',
        ]);

        $this->postJson('/api/rooms/KX7P2A/join', ['nickname' => 'Diego'])->assertCreated();

        $this->assertDatabaseHas('players', ['nickname' => 'Diego']);
    }
}
