<?php

namespace App\Models;

use Database\Factories\TopicFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Topic extends Model
{
    /** @use HasFactory<TopicFactory> */
    use HasFactory;

    protected $fillable = ['name', 'slug', 'icon', 'color'];

    public function questions(): HasMany
    {
        return $this->hasMany(Question::class);
    }

    public function rooms(): HasMany
    {
        return $this->hasMany(Room::class);
    }
}
