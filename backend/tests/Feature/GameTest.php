<?php

namespace Tests\Feature;

use App\Enums\RoomStatus;
use App\Events\PartidaIniciada;
use App\Events\PartidaTerminada;
use App\Events\PreguntaCerrada;
use App\Events\PreguntaMostrada;
use App\Events\RespuestaRecibida;
use App\Jobs\CerrarPregunta;
use App\Models\Player;
use App\Models\Question;
use App\Models\Room;
use App\Models\Topic;
use App\Models\User;
use App\Services\GameService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Queue;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class GameTest extends TestCase
{
    use RefreshDatabase;

    private User $host;

    private Room $room;

    private Player $ana;

    private Player $beto;

    protected function setUp(): void
    {
        parent::setUp();

        Event::fake([
            PartidaIniciada::class,
            PreguntaMostrada::class,
            RespuestaRecibida::class,
            PreguntaCerrada::class,
            PartidaTerminada::class,
        ]);
        Queue::fake();

        $topic = Topic::factory()->create();
        $questions = Question::factory()->count(2)->for($topic)->withOptions()->create();

        $this->host = User::factory()->create();
        $this->room = Room::create([
            'code' => 'KX7P2A',
            'host_id' => $this->host->id,
            'topic_id' => $topic->id,
            'seconds_per_question' => 30,
            'total_questions' => 2,
        ]);
        foreach ($questions as $i => $question) {
            $this->room->roomQuestions()->create(['question_id' => $question->id, 'position' => $i + 1]);
        }
        $this->ana = $this->room->players()->create(['nickname' => 'Ana', 'token' => str_repeat('a', 64)]);
        $this->beto = $this->room->players()->create(['nickname' => 'Beto', 'token' => str_repeat('b', 64)]);
    }

    private function empezar(): void
    {
        Sanctum::actingAs($this->host);
        $this->postJson('/api/rooms/KX7P2A/start')->assertOk();
    }

    private function opcion(bool $correcta, int $posicion = 1): int
    {
        $question = $this->room->roomQuestions()->where('position', $posicion)->first()->question;

        return $question->options()->where('is_correct', $correcta)->first()->id;
    }

    private function responder(Player $player, int $optionId)
    {
        return $this->postJson('/api/rooms/KX7P2A/answer', ['option_id' => $optionId], ['X-Player-Token' => $player->token]);
    }

    public function test_solo_el_anfitrion_puede_empezar(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/rooms/KX7P2A/start')->assertForbidden();
    }

    public function test_no_se_puede_empezar_sin_jugadores(): void
    {
        $this->room->players()->delete();
        Sanctum::actingAs($this->host);

        $this->postJson('/api/rooms/KX7P2A/start')
            ->assertStatus(422)
            ->assertJsonPath('errors.room.0', 'Esperá a que entre al menos un jugador.');
    }

    public function test_al_empezar_se_muestra_la_primera_pregunta_sin_revelar_la_correcta(): void
    {
        $this->freezeSecond();
        $this->empezar();

        $this->assertSame(RoomStatus::Playing, $this->room->fresh()->status);
        Event::assertDispatched(PartidaIniciada::class);
        Event::assertDispatched(PreguntaMostrada::class, function (PreguntaMostrada $evento) {
            $datos = $evento->broadcastWith();

            return $evento->broadcastOn()->name === 'sala.KX7P2A'
                && $datos['position'] === 1
                && $datos['seconds'] === 30
                && count($datos['options']) === 4
                && ! str_contains(json_encode($datos), 'is_correct');
        });

        $primera = $this->room->roomQuestions()->where('position', 1)->first();
        $this->assertTrue($primera->ends_at->equalTo(now()->addSeconds(30)));
        Queue::assertPushed(CerrarPregunta::class, fn ($job) => $job->roomQuestion->is($primera));
    }

    public function test_el_jugador_responde_y_se_guarda_si_acerto(): void
    {
        $this->empezar();

        $this->responder($this->ana, $this->opcion(true))
            ->assertCreated()
            ->assertExactJson(['received' => true]);

        $this->assertDatabaseHas('answers', ['player_id' => $this->ana->id, 'is_correct' => true]);
        Event::assertDispatched(RespuestaRecibida::class, fn ($e) => $e->broadcastWith() === ['answered' => 1, 'players' => 2]);
        Event::assertNotDispatched(PreguntaCerrada::class);
    }

    public function test_no_se_puede_responder_dos_veces(): void
    {
        $this->empezar();
        $this->responder($this->ana, $this->opcion(false))->assertCreated();

        $this->responder($this->ana, $this->opcion(true))
            ->assertStatus(422)
            ->assertJsonPath('errors.option_id.0', 'Ya respondiste esta pregunta.');
    }

    public function test_una_respuesta_que_llega_tarde_no_vale(): void
    {
        $this->empezar();
        $this->travel(31)->seconds();

        $this->responder($this->ana, $this->opcion(true))
            ->assertStatus(422)
            ->assertJsonPath('errors.option_id.0', '¡Se terminó el tiempo!');
    }

    public function test_no_vale_una_opcion_de_otra_pregunta(): void
    {
        $this->empezar();

        $this->responder($this->ana, $this->opcion(true, posicion: 2))
            ->assertStatus(422)
            ->assertJsonPath('errors.option_id.0', 'Esa opción no es de esta pregunta.');
    }

    public function test_sin_token_de_jugador_no_se_puede_responder(): void
    {
        $this->empezar();

        $this->postJson('/api/rooms/KX7P2A/answer', ['option_id' => $this->opcion(true)], ['X-Player-Token' => 'inventado'])
            ->assertUnauthorized();
    }

    public function test_si_responden_todos_la_pregunta_se_cierra_antes(): void
    {
        $this->empezar();
        $this->responder($this->ana, $this->opcion(true))->assertCreated();
        $this->responder($this->beto, $this->opcion(false))->assertCreated();

        $this->assertSame(RoomStatus::ShowingResults, $this->room->fresh()->status);
        Event::assertDispatched(PreguntaCerrada::class, function (PreguntaCerrada $evento) {
            $datos = $evento->broadcastWith();

            return $datos['correct_option_id'] === $this->opcion(true)
                && $datos['answered'] === 2
                && $datos['correct'] === 1
                && $datos['is_last'] === false;
        });
    }

    public function test_el_job_cierra_la_pregunta_una_sola_vez(): void
    {
        $this->empezar();
        $primera = $this->room->roomQuestions()->where('position', 1)->first();

        (new CerrarPregunta($primera))->handle(app(GameService::class));
        (new CerrarPregunta($primera))->handle(app(GameService::class));

        Event::assertDispatchedTimes(PreguntaCerrada::class, 1);
        $this->assertNotNull($primera->fresh()->closed_at);
    }

    public function test_el_anfitrion_avanza_y_al_final_termina_la_partida(): void
    {
        $this->empezar();

        // Mientras se juega la pregunta, no se puede saltar a la siguiente.
        $this->postJson('/api/rooms/KX7P2A/next')->assertStatus(422);

        app(GameService::class)->closeQuestion($this->room->fresh()->currentRoomQuestion());
        $this->postJson('/api/rooms/KX7P2A/next')->assertOk();
        $this->assertSame(2, $this->room->fresh()->current_index);

        app(GameService::class)->closeQuestion($this->room->fresh()->currentRoomQuestion());
        $this->postJson('/api/rooms/KX7P2A/next')->assertOk();

        $this->assertSame(RoomStatus::Finished, $this->room->fresh()->status);
        Event::assertDispatched(PartidaTerminada::class);
    }
}
