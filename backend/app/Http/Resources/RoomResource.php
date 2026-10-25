<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RoomResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'code' => $this->code,
            'status' => $this->status,
            'seconds_per_question' => $this->seconds_per_question,
            'total_questions' => $this->total_questions,
            'topic' => new TopicResource($this->whenLoaded('topic')),
            'host' => $this->whenLoaded('host', fn () => $this->host->name),
            'players' => PlayerResource::collection($this->whenLoaded('players')),
        ];
    }
}
