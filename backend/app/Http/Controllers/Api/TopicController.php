<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\TopicResource;
use App\Models\Topic;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class TopicController extends Controller
{
    /**
     * GET /api/topics: los temas que el anfitrión puede elegir.
     */
    public function index(): AnonymousResourceCollection
    {
        $topics = Topic::withCount('questions')->orderBy('name')->get();

        return TopicResource::collection($topics);
    }
}
