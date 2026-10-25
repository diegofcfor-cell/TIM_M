<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Cada respuesta dada por un jugador.
     */
    public function up(): void
    {
        Schema::create('answers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('player_id')->constrained()->cascadeOnDelete();
            $table->foreignId('room_question_id')->constrained()->cascadeOnDelete();
            $table->foreignId('option_id')->constrained();
            $table->boolean('is_correct');
            $table->unsignedSmallInteger('points')->default(0);
            $table->timestamp('answered_at');
            $table->timestamps();

            // Regla de la base de datos: un jugador responde una sola vez cada pregunta.
            $table->unique(['player_id', 'room_question_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('answers');
    }
};
