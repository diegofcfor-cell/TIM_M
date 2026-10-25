<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

/**
 * Login del anfitrión. Devuelve un token de Sanctum que la app guarda
 * y manda en cada pedido con el encabezado "Authorization: Bearer <token>".
 */
class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:50'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8'],
        ], [
            'email.unique' => 'Ya existe una cuenta con ese email.',
            'password.min' => 'La contraseña tiene que tener al menos 8 caracteres.',
        ]);

        $user = User::create($data);

        return $this->respondWithToken($user, 201);
    }

    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::where('email', $data['email'])->first();

        if (! $user || ! Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => 'El email o la contraseña no son correctos.',
            ]);
        }

        return $this->respondWithToken($user);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Sesión cerrada.']);
    }

    private function respondWithToken(User $user, int $status = 200): JsonResponse
    {
        return response()->json([
            'token' => $user->createToken('app')->plainTextToken,
            'user' => $user->only('id', 'name', 'email'),
        ], $status);
    }
}
