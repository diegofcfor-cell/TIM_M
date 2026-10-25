<?php

namespace App\Models;

use App\Enums\RoomStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

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

    /**
     * Valores iniciales de una sala nueva (los mismos que en la migración).
     */
    protected $attributes = [
        'status' => 'waiting',
        'seconds_per_question' => 30,
        'total_questions' => 10,
    ];

    protected function casts(): array
    {
        return [
            'status' => RoomStatus::class,
        ];
    }

    /**
     * Letras y números fáciles de leer en voz alta: sin O/0 ni I/1.
     */
    private const CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    /**
     * Genera un código de 6 caracteres que ninguna otra sala esté usando.
     */
    public static function generateUniqueCode(): string
    {
        do {
            $code = '';
            for ($i = 0; $i < 6; $i++) {
                $code .= self::CODE_ALPHABET[random_int(0, strlen(self::CODE_ALPHABET) - 1)];
            }
        } while (self::where('code', $code)->exists());

        return $code;
    }

    /**
     * Permite usar el código en la URL (/api/rooms/kx7p2a) sin importar
     * mayúsculas o minúsculas.
     */
    public function resolveRouteBinding($value, $field = null)
    {
        return $this->where($field ?? 'code', Str::upper($value))->firstOrFail();
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
