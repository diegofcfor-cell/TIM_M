<?php

namespace App\Http\Requests;

use App\Models\Topic;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class StoreRoomRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'topic_id' => ['required', 'integer', 'exists:topics,id'],
            'seconds_per_question' => ['required', 'integer', Rule::in([30, 60])],
            'total_questions' => ['sometimes', 'integer', 'min:3', 'max:20'],
        ];
    }

    public function messages(): array
    {
        return [
            'topic_id.exists' => 'Ese tema no existe.',
            'seconds_per_question.in' => 'El tiempo por pregunta tiene que ser 30 o 60 segundos.',
            'total_questions.min' => 'La partida tiene que tener al menos 3 preguntas.',
            'total_questions.max' => 'La partida puede tener como máximo 20 preguntas.',
        ];
    }

    /**
     * Además de las reglas, revisamos que el tema tenga suficientes preguntas.
     */
    public function after(): array
    {
        return [
            function (Validator $validator) {
                $topic = Topic::withCount('questions')->find($this->input('topic_id'));

                if ($topic && $topic->questions_count < $this->totalQuestions()) {
                    $validator->errors()->add(
                        'total_questions',
                        "El tema {$topic->name} tiene solo {$topic->questions_count} preguntas."
                    );
                }
            },
        ];
    }

    public function totalQuestions(): int
    {
        return (int) $this->input('total_questions', 10);
    }
}
