<?php

namespace Tests\Feature;

use App\Events\PartidaIniciada;
use App\Events\PartidaTerminada;
use App\Events\PreguntaCerrada;
use App\Events\PreguntaMostrada;
use App\Events\RespuestaRecibida;
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

class PuntosTest extends TestCase
{
    use RefreshDatabase;

    private User $host;

    private Room $room;

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
        $this->freezeSecond();

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

        Sanctum::actingAs($this->host);
    }

    private function jugador(string $apodo): Player
    {
        return $this->room->players()->create(['nickname' => $apodo, 'token' => str_pad($apodo, 64, 'x')]);
    }

    private function opcion(bool $correcta): int
    {
        $question = $this->room->fresh()->currentRoomQuestion()->question;

        return $question->options()->where('is_correct', $correcta)->first()->id;
    }

    private function responder(Player $player, bool $correcta): void
    {
        $this->postJson('/api/rooms/KX7P2A/answer', ['option_id' => $this->opcion($correcta)], ['X-Player-Token' => $player->token])
            ->assertCreated();
    }

    private function cerrarYSeguir(): void
    {
        app(GameService::class)->closeQuestion($this->room->fresh()->currentRoomQuestion());
        $this->postJson('/api/rooms/KX7P2A/next')->assertOk();
    }

    public function test_acertar_rapido_vale_casi_1000_y_tarde_casi_500(): void
    {
        $ana = $this->jugador('Ana');
        $beto = $this->jugador('Beto');
        $caro = $this->jugador('Caro');
        $this->postJson('/api/rooms/KX7P2A/start')->assertOk();

        $this->responder($ana, true);            // a los 0 s: 500 + 500
        $this->travel(15)->seconds();
        $this->responder($beto, true);           // a los 15 s: 500 + 250
        $this->travel(15)->seconds();
        $this->responder($caro, false);          // equivocada: 0

        $this->assertSame([1000, 750, 0], [$ana->fresh()->score, $beto->fresh()->score, $caro->fresh()->score]);
        $this->assertDatabaseHas('answers', ['player_id' => $beto->id, 'points' => 750]);
    }

    public function test_al_cerrar_la_pregunta_llega_el_ranking_con_los_puntos_de_cada_uno(): void
    {
        $ana = $this->jugador('Ana');
        $beto = $this->jugador('Beto');
        $this->postJson('/api/rooms/KX7P2A/start')->assertOk();

        $this->travel(6)->seconds();
        $this->responder($beto, true);           // 500 + 400
        $this->responder($ana, false);

        Event::assertDispatched(PreguntaCerrada::class, function (PreguntaCerrada $evento) use ($ana, $beto) {
            return $evento->broadcastWith()['ranking'] === [
                ['position' => 1, 'id' => $beto->id, 'nickname' => 'Beto', 'score' => 900, 'points' => 900],
                ['position' => 2, 'id' => $ana->id, 'nickname' => 'Ana', 'score' => 0, 'points' => 0],
            ];
        });
    }

    public function test_el_podio_final_suma_todas_las_preguntas_y_respeta_los_empates(): void
    {
        $ana = $this->jugador('Ana');
        $beto = $this->jugador('Beto');
        $caro = $this->jugador('Caro');
        $this->postJson('/api/rooms/KX7P2A/start')->assertOk();

        // Pregunta 1: Ana y Beto aciertan al instante; Caro no responde.
        $this->responder($ana, true);
        $this->responder($beto, true);
        $this->cerrarYSeguir();

        // Pregunta 2: solo Caro acierta, en el último segundo exacto.
        $this->travel(30)->seconds();
        $this->responder($caro, true);
        $this->cerrarYSeguir();

        Event::assertDispatched(PartidaTerminada::class, function (PartidaTerminada $evento) use ($ana, $beto, $caro) {
            return $evento->broadcastWith()['ranking'] === [
                ['position' => 1, 'id' => $ana->id, 'nickname' => 'Ana', 'score' => 1000],
                ['position' => 1, 'id' => $beto->id, 'nickname' => 'Beto', 'score' => 1000],
                ['position' => 3, 'id' => $caro->id, 'nickname' => 'Caro', 'score' => 500],
            ];
        });
    }
}
