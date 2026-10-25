<?php

namespace Tests\Feature;

use App\Enums\RoomStatus;
use App\Models\Question;
use App\Models\Room;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class GameModelsTest extends TestCase
{
    use RefreshDatabase;

    private function crearPartida(): array
    {
        $question = Question::factory()->withOptions()->create();
        $room = Room::create([
            'code' => 'KX7P2A',
            'host_id' => User::factory()->create()->id,
            'topic_id' => $question->topic_id,
            'seconds_per_question' => 30,
        ]);
        $roomQuestion = $room->roomQuestions()->create([
            'question_id' => $question->id,
            'position' => 1,
        ]);
        $player = $room->players()->create(['nickname' => 'Diego', 'token' => str_repeat('a', 64)]);

        return [$room, $roomQuestion, $player, $question];
    }

    public function test_una_sala_nueva_empieza_esperando_jugadores(): void
    {
        [$room] = $this->crearPartida();

        $this->assertSame(RoomStatus::Waiting, $room->fresh()->status);
        $this->assertSame(10, $room->fresh()->total_questions);
    }

    public function test_las_relaciones_conectan_sala_jugadores_y_respuestas(): void
    {
        [$room, $roomQuestion, $player, $question] = $this->crearPartida();

        $player->answers()->create([
            'room_question_id' => $roomQuestion->id,
            'option_id' => $question->correctOption->id,
            'is_correct' => true,
            'points' => 900,
            'answered_at' => now(),
        ]);

        $this->assertTrue($room->host->rooms->contains($room));
        $this->assertSame('Diego', $room->players->first()->nickname);
        $this->assertSame(900, $roomQuestion->answers->first()->points);
        $this->assertArrayNotHasKey('token', $player->toArray());
    }

    public function test_un_jugador_no_puede_responder_dos_veces_la_misma_pregunta(): void
    {
        [, $roomQuestion, $player, $question] = $this->crearPartida();
        $respuesta = [
            'room_question_id' => $roomQuestion->id,
            'option_id' => $question->options->first()->id,
            'is_correct' => false,
            'answered_at' => now(),
        ];

        $player->answers()->create($respuesta);

        $this->expectException(QueryException::class);
        $player->answers()->create($respuesta);
    }
}
