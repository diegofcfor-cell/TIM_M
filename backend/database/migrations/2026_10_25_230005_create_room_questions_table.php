<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Qué preguntas tocaron en cada sala, en qué orden y cuándo termina cada una.
     */
    public function up(): void
    {
        Schema::create('room_questions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('room_id')->constrained()->cascadeOnDelete();
            $table->foreignId('question_id')->constrained();
            $table->unsignedTinyInteger('position');
            $table->timestamp('started_at')->nullable();
            $table->timestamp('ends_at')->nullable();
            $table->timestamps();

            $table->unique(['room_id', 'position']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('room_questions');
    }
};
