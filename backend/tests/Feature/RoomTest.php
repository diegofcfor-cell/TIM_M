<?php

namespace Tests\Feature;

use App\Models\Question;
use App\Models\Room;
use App\Models\Topic;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class RoomTest extends TestCase
{
    use RefreshDatabase;

    private Topic $topic;

    protected function setUp(): void
    {
        parent::setUp();

        $this->topic = Topic::factory()->create(['name' => 'Música']);
        Question::factory()->count(12)->for($this->topic)->create();
    }

    public function test_crear_una_sala_necesita_login(): void
    {
        $this->postJson('/api/rooms', ['topic_id' => $this->topic->id, 'seconds_per_question' => 30])
            ->assertUnauthorized();
    }

    public function test_el_anfitrion_crea_una_sala_con_codigo_y_preguntas_sorteadas(): void
    {
        Sanctum::actingAs($host = User::factory()->create());

        $response = $this->postJson('/api/rooms', [
            'topic_id' => $this->topic->id,
            'seconds_per_question' => 60,
            'total_questions' => 5,
        ])->assertCreated()
            ->assertJsonPath('data.status', 'waiting')
            ->assertJsonPath('data.seconds_per_question', 60)
            ->assertJsonPath('data.topic.name', 'Música')
            ->assertJsonPath('data.host', $host->name)
            ->assertJsonPath('data.players', []);

        $code = $response->json('data.code');
        $this->assertMatchesRegularExpression('/^[A-HJ-NP-Z2-9]{6}$/', $code);

        $room = Room::where('code', $code)->firstOrFail();
        $this->assertSame([1, 2, 3, 4, 5], $room->roomQuestions->pluck('position')->all());
        $this->assertCount(5, $room->roomQuestions->pluck('question_id')->unique());
    }

    public function test_el_tiempo_por_pregunta_solo_puede_ser_30_o_60(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/rooms', ['topic_id' => $this->topic->id, 'seconds_per_question' => 45])
            ->assertStatus(422)
            ->assertJsonValidationErrors('seconds_per_question');
    }

    public function test_no_se_piden_mas_preguntas_de_las_que_tiene_el_tema(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/rooms', [
            'topic_id' => $this->topic->id,
            'seconds_per_question' => 30,
            'total_questions' => 15,
        ])->assertStatus(422)
            ->assertJsonPath('errors.total_questions.0', 'El tema Música tiene solo 12 preguntas.');
    }

    public function test_cualquiera_ve_la_sala_con_el_codigo_en_minusculas_o_mayusculas(): void
    {
        $room = Room::create([
            'code' => 'KX7P2A',
            'host_id' => User::factory()->create()->id,
            'topic_id' => $this->topic->id,
        ]);
        $room->players()->create(['nickname' => 'Ana', 'token' => str_repeat('t', 64)]);

        $this->getJson('/api/rooms/kx7p2a')
            ->assertOk()
            ->assertJsonPath('data.code', 'KX7P2A')
            ->assertJsonPath('data.players.0.nickname', 'Ana')
            ->assertJsonMissingPath('data.players.0.token');

        $this->getJson('/api/rooms/ZZZZZZ')->assertNotFound();
    }
}
