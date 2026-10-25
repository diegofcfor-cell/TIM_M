<?php

namespace Database\Factories;

use App\Models\Question;
use App\Models\Topic;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Question>
 */
class QuestionFactory extends Factory
{
    public function definition(): array
    {
        return [
            'topic_id' => Topic::factory(),
            'text' => fake()->sentence().'?',
            'difficulty' => 'media',
        ];
    }

    /**
     * Agrega las 4 opciones: la primera es la correcta.
     */
    public function withOptions(): static
    {
        return $this->afterCreating(function (Question $question) {
            foreach (range(0, 3) as $i) {
                $question->options()->create([
                    'text' => fake()->word(),
                    'is_correct' => $i === 0,
                ]);
            }
        });
    }
}
