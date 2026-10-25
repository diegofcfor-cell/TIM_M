<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Cuándo se cerró la pregunta (por tiempo o porque respondieron todos).
     */
    public function up(): void
    {
        Schema::table('room_questions', function (Blueprint $table) {
            $table->timestamp('closed_at')->nullable()->after('ends_at');
        });
    }

    public function down(): void
    {
        Schema::table('room_questions', function (Blueprint $table) {
            $table->dropColumn('closed_at');
        });
    }
};
