<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Cada partida. El anfitrión (host) es un usuario con cuenta.
     */
    public function up(): void
    {
        Schema::create('rooms', function (Blueprint $table) {
            $table->id();
            $table->string('code', 6)->unique();
            $table->foreignId('host_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('topic_id')->constrained();
            $table->unsignedTinyInteger('seconds_per_question')->default(30);
            $table->unsignedTinyInteger('total_questions')->default(10);
            $table->string('status')->default('waiting');
            $table->unsignedTinyInteger('current_index')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('rooms');
    }
};
