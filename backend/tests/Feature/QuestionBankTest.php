<?php

namespace Tests\Feature;

use App\Models\Question;
use App\Models\Topic;
use Database\Seeders\QuestionBankSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Revisa que el banco de preguntas esté bien armado antes de jugar.
 */
class QuestionBankTest extends TestCase
{
    use RefreshDatabase;

    public function test_cada_tema_tiene_al_menos_20_preguntas(): void
    {
        $this->seed(QuestionBankSeeder::class);

        $topics = Topic::withCount('questions')->get();

        $this->assertCount(6, $topics);
        foreach ($topics as $topic) {
            $this->assertGreaterThanOrEqual(20, $topic->questions_count, $topic->name);
        }
    }

    public function test_cada_pregunta_tiene_4_opciones_distintas_y_una_sola_correcta(): void
    {
        $this->seed(QuestionBankSeeder::class);

        foreach (Question::with('options')->get() as $question) {
            $this->assertCount(4, $question->options, $question->text);
            $this->assertCount(1, $question->options->where('is_correct', true), $question->text);
            $this->assertCount(4, $question->options->pluck('text')->unique(), $question->text);
        }
    }

    public function test_correr_el_seeder_dos_veces_no_duplica_nada(): void
    {
        $this->seed(QuestionBankSeeder::class);
        $this->seed(QuestionBankSeeder::class);

        $this->assertSame(6, Topic::count());
        $this->assertSame(120, Question::count());
        $this->assertDatabaseCount('options', 480);
    }
}
