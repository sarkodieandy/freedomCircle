<?php

return [
    'supabase' => [
        'url' => env('SUPABASE_URL'),
        'db_url' => env('SUPABASE_DB_URL'),
        'service_role_key' => env('SUPABASE_SERVICE_ROLE_KEY'),
        'anon_key' => env('SUPABASE_ANON_KEY'),
    ],

    'paystack' => [
        'secret_key' => env('PAYSTACK_SECRET_KEY'),
        'public_key' => env('PAYSTACK_PUBLIC_KEY'),
        'webhook_secret' => env('PAYSTACK_WEBHOOK_SECRET'),
    ],

    'revenuecat' => [
        'webhook_secret' => env('REVENUECAT_WEBHOOK_SECRET'),
    ],
];
