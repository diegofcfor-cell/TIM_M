<?php

namespace App\Models;

use App\Enums\RoomStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Room extends Model
{
    protected $fillable = [
        'code',
        'host_id',
        'topic_id',
        'seconds_per_question',
        'total_questions',
        'status',
        'current_index',
    ];

    protected function casts(): array
    {
        return [
            'status' => RoomStatus::class,
        ];
    }

    public function host(): BelongsTo
    {
        return $this->belongsTo(User::class, 'host_id');
    }

    public function topic(): BelongsTo
    {
        return $this->belongsTo(Topic::class);
    }

    public function players(): HasMany
    {
        return $this->hasMany(Player::class);
    }

    public function roomQuestions(): HasMany
    {
        return $this->hasMany(RoomQuestion::class)->orderBy('position');
    }
}
