<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class JoinRoomRequest extends FormRequest
{
    /**
     * Quitamos espacios de más antes de validar: " Diego " es "Diego".
     */
    protected function prepareForValidation(): void
    {
        $this->merge(['nickname' => trim((string) $this->input('nickname'))]);
    }

    public function rules(): array
    {
        return [
            'nickname' => [
                'required',
                'string',
                'max:20',
                Rule::unique('players')->where('room_id', $this->route('room')->id),
            ],
        ];
    }

    public function messages(): array
    {
        return [
            'nickname.required' => 'Escribí un apodo para entrar.',
            'nickname.max' => 'El apodo puede tener como máximo 20 caracteres.',
            'nickname.unique' => 'Ese apodo ya está en uso en esta sala. Probá con otro.',
        ];
    }
}
