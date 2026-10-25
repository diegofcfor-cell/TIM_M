<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_el_anfitrion_inicia_sesion_y_recibe_un_token(): void
    {
        User::factory()->create(['email' => 'diego@trivia.test', 'password' => 'secreto123']);

        $token = $this->postJson('/api/login', ['email' => 'diego@trivia.test', 'password' => 'secreto123'])
            ->assertOk()
            ->assertJsonPath('user.email', 'diego@trivia.test')
            ->json('token');

        $this->withToken($token)->getJson('/api/user')->assertOk();
    }

    public function test_con_la_contrasena_incorrecta_no_entra(): void
    {
        User::factory()->create(['email' => 'diego@trivia.test', 'password' => 'secreto123']);

        $this->postJson('/api/login', ['email' => 'diego@trivia.test', 'password' => 'otra'])
            ->assertStatus(422)
            ->assertJsonPath('errors.email.0', 'El email o la contraseña no son correctos.');
    }

    public function test_se_puede_crear_una_cuenta_nueva(): void
    {
        $this->postJson('/api/register', [
            'name' => 'Diego',
            'email' => 'nuevo@trivia.test',
            'password' => 'secreto123',
        ])->assertCreated()->assertJsonStructure(['token', 'user' => ['id', 'name', 'email']]);

        $this->assertDatabaseHas('users', ['email' => 'nuevo@trivia.test']);
    }
}
