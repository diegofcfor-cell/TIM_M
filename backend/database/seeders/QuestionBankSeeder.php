<?php

namespace Database\Seeders;

use App\Models\Topic;
use Illuminate\Database\Seeder;

/**
 * Carga los temas y las preguntas de database/data/preguntas.php.
 *
 * Se puede correr varias veces: no duplica temas ni preguntas.
 */
class QuestionBankSeeder extends Seeder
{
    public function run(): void
    {
        $topics = require database_path('data/preguntas.php');

        foreach ($topics as $data) {
            $topic = Topic::updateOrCreate(
                ['slug' => $data['slug']],
                ['name' => $data['name'], 'icon' => $data['icon'], 'color' => $data['color']],
            );

            foreach ($data['questions'] as [$text, $difficulty, $correct, $wrong]) {
                $question = $topic->questions()->firstOrCreate(
                    ['text' => $text],
                    ['difficulty' => $difficulty],
                );

                if ($question->options()->exists()) {
                    continue;
                }

                $options = [['text' => $correct, 'is_correct' => true]];
                foreach ($wrong as $option) {
                    $options[] = ['text' => $option, 'is_correct' => false];
                }

                // Mezclamos para que la correcta no quede siempre primera.
                shuffle($options);
                $question->options()->createMany($options);
            }
        }
    }
}
