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
        // Un anfitrión de prueba para crear salas (contraseña: password).
        User::firstOrCreate(
            ['email' => 'anfitrion@trivia.test'],
            ['name' => 'Anfitrión de prueba', 'password' => 'password'],
        );

        $this->call(QuestionBankSeeder::class);
    }
}
