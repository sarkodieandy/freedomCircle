<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('app_settings', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->string('key', 160)->unique();
            $table->json('value')->nullable();
            $table->string('group', 120)->default('general');
            $table->string('type', 60)->default('string');
            $table->text('description')->nullable();
            $table->boolean('is_public')->default(false);
            $table->uuid('updated_by')->nullable();
            $table->timestamps();

            $table->index(['group', 'is_public']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('app_settings');
    }
};
