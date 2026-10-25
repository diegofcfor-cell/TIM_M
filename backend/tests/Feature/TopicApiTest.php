<?php

namespace Tests\Feature;

use App\Models\Question;
use App\Models\Topic;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TopicApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_lista_los_temas_con_su_cantidad_de_preguntas(): void
    {
        $musica = Topic::factory()->create(['name' => 'Música', 'slug' => 'musica']);
        Topic::factory()->create(['name' => 'Cine', 'slug' => 'cine']);
        Question::factory()->count(3)->for($musica)->create();

        $this->getJson('/api/topics')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.name', 'Cine')
            ->assertJsonPath('data.0.questions_count', 0)
            ->assertJsonPath('data.1.slug', 'musica')
            ->assertJsonPath('data.1.questions_count', 3)
            ->assertJsonStructure(['data' => [['id', 'name', 'slug', 'icon', 'color', 'questions_count']]]);
    }
}
