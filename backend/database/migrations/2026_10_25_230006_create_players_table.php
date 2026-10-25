<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Jugadores invitados: entran sin cuenta, con un apodo.
     * El token es la clave secreta que la app guarda en el celular.
     */
    public function up(): void
    {
        Schema::create('players', function (Blueprint $table) {
            $table->id();
            $table->foreignId('room_id')->constrained()->cascadeOnDelete();
            $table->string('nickname', 30);
            $table->string('token', 64)->unique();
            $table->unsignedInteger('score')->default(0);
            $table->timestamps();

            $table->unique(['room_id', 'nickname']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('players');
    }
};
