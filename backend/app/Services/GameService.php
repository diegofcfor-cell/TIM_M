<?php

namespace App\Services;

use App\Enums\RoomStatus;
use App\Events\PartidaIniciada;
use App\Events\PartidaTerminada;
use App\Events\PreguntaCerrada;
use App\Events\PreguntaMostrada;
use App\Events\RespuestaRecibida;
use App\Jobs\CerrarPregunta;
use App\Models\Answer;
use App\Models\Option;
use App\Models\Player;
use App\Models\Room;
use App\Models\RoomQuestion;
use App\Support\EnVivo;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Validation\ValidationException;

/**
 * Las reglas del juego. El servidor es el árbitro: decide cuándo empieza
 * y termina cada pregunta, y si una respuesta llegó a tiempo.
 */
class GameService
{
    public function start(Room $room): void
    {
        if ($room->status !== RoomStatus::Waiting) {
            throw ValidationException::withMessages(['room' => 'La partida ya empezó.']);
        }
        if (! $room->players()->exists()) {
            throw ValidationException::withMessages(['room' => 'Esperá a que entre al menos un jugador.']);
        }

        EnVivo::emitir(new PartidaIniciada($room));
        $this->showQuestion($room, 1);
    }

    /**
     * Pasa a la siguiente pregunta, o termina la partida si era la última.
     */
    public function next(Room $room): void
    {
        if ($room->status !== RoomStatus::ShowingResults) {
            throw ValidationException::withMessages(['room' => 'Todavía se está jugando la pregunta actual.']);
        }

        if ($room->current_index >= $room->total_questions) {
            $room->update(['status' => RoomStatus::Finished]);
            EnVivo::emitir(new PartidaTerminada($room));

            return;
        }

        $this->showQuestion($room, $room->current_index + 1);
    }

    public function answer(Room $room, Player $player, int $optionId): Answer
    {
        $roomQuestion = $room->currentRoomQuestion();

        // El reloj del servidor decide. El del celular no cuenta.
        if ($room->status !== RoomStatus::Playing || ! $roomQuestion
            || $roomQuestion->closed_at || now()->greaterThan($roomQuestion->ends_at)) {
            throw ValidationException::withMessages(['option_id' => '¡Se terminó el tiempo!']);
        }

        $option = Option::where('question_id', $roomQuestion->question_id)->find($optionId);
        if (! $option) {
            throw ValidationException::withMessages(['option_id' => 'Esa opción no es de esta pregunta.']);
        }

        try {
            $answer = $player->answers()->create([
                'room_question_id' => $roomQuestion->id,
                'option_id' => $option->id,
                'is_correct' => $option->is_correct,
                'answered_at' => now(),
            ]);
        } catch (UniqueConstraintViolationException) {
            throw ValidationException::withMessages(['option_id' => 'Ya respondiste esta pregunta.']);
        }

        EnVivo::emitir(new RespuestaRecibida($roomQuestion));

        // Si ya respondieron todos, no hace falta esperar al reloj.
        if ($roomQuestion->answers()->count() >= $room->players()->count()) {
            $this->closeQuestion($roomQuestion);
        }

        return $answer;
    }

    /**
     * Cierra la pregunta y revela la respuesta correcta. Lo llama el job
     * CerrarPregunta cuando se acaba el tiempo, o answer() si respondieron
     * todos antes. Si ya estaba cerrada, no hace nada.
     */
    public function closeQuestion(RoomQuestion $roomQuestion): void
    {
        // Solo uno de los dos caminos "gana": el que logra poner closed_at.
        $closed = RoomQuestion::whereKey($roomQuestion->id)
            ->whereNull('closed_at')
            ->update(['closed_at' => now()]);

        if (! $closed) {
            return;
        }

        $roomQuestion->room->update(['status' => RoomStatus::ShowingResults]);
        EnVivo::emitir(new PreguntaCerrada($roomQuestion->fresh()));
    }

    private function showQuestion(Room $room, int $position): void
    {
        $roomQuestion = $room->roomQuestions()->where('position', $position)->firstOrFail();
        $roomQuestion->update([
            'started_at' => now(),
            'ends_at' => now()->addSeconds($room->seconds_per_question),
        ]);
        $room->update(['status' => RoomStatus::Playing, 'current_index' => $position]);

        EnVivo::emitir(new PreguntaMostrada($roomQuestion));

        // Un trabajo en la cola cierra la pregunta cuando se acaba el tiempo.
        CerrarPregunta::dispatch($roomQuestion)->delay($roomQuestion->ends_at);
    }
}
