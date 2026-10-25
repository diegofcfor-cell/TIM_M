<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Player extends Model
{
    protected $fillable = ['room_id', 'nickname', 'token', 'score'];

    /**
     * El token es secreto: nunca se manda en las respuestas JSON.
     */
    protected $hidden = ['token'];

    public function room(): BelongsTo
    {
        return $this->belongsTo(Room::class);
    }

    public function answers(): HasMany
    {
        return $this->hasMany(Answer::class);
    }
}
