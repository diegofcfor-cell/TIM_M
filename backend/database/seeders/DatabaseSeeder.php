<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Un anfitrión para crear salas. En tu compu la contraseña es
        // "password"; en internet sale de la variable ANFITRION_PASSWORD.
        User::firstOrCreate(
            ['email' => 'anfitrion@trivia.test'],
            ['name' => 'Anfitrión de prueba', 'password' => config('app.anfitrion_password')],
        );

        $this->call(QuestionBankSeeder::class);
    }
}
