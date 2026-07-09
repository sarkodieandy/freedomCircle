<?php

return [
    'middleware_aliases' => [
        'admin.auth' => App\Http\Middleware\EnsureAdminAuthenticated::class,
        'admin.role' => App\Http\Middleware\EnsureAdminRole::class,
    ],
];
