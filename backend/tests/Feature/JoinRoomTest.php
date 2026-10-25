<?php

namespace Tests\Feature;

use App\Enums\RoomStatus;
use App\Models\Room;
use App\Models\Topic;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
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
}
