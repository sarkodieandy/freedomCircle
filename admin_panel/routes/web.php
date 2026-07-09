<?php

use App\Http\Controllers\Admin\AdminModuleController;
use App\Http\Controllers\Admin\AppSettingsController;
use App\Http\Controllers\Admin\AuditLogController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\QuietTimeVideoAdminController;
use App\Http\Controllers\Admin\SearchController;
use App\Http\Controllers\Admin\Auth\AdminAuthController;
use Illuminate\Support\Facades\Route;

Route::middleware('web')->group(function (): void {
    Route::get('/admin/login', [AdminAuthController::class, 'showLogin'])
        ->name('admin.login');
    Route::post('/admin/login', [AdminAuthController::class, 'login'])
        ->middleware('throttle:10,1')
        ->name('admin.login.submit');
    Route::post('/admin/logout', [AdminAuthController::class, 'logout'])
        ->middleware('admin.auth')
        ->name('admin.logout');

    Route::prefix('admin')->middleware('admin.auth')->group(function (): void {
        Route::get('/', [DashboardController::class, 'index'])
            ->middleware('admin.role:dashboard.view')
            ->name('admin.dashboard');

        Route::get('/search', [SearchController::class, 'index'])
            ->middleware('admin.role:search.view')
            ->name('admin.search');

        Route::prefix('app-settings')->middleware('admin.role:settings.manage')->group(function (): void {
            Route::get('/', [AppSettingsController::class, 'index'])->name('admin.app-settings.index');
            Route::put('/group/{group}', [AppSettingsController::class, 'updateGroup'])->name('admin.app-settings.update-group');
            Route::match(['post', 'put'], '/{key}/reset', [AppSettingsController::class, 'reset'])->name('admin.app-settings.reset');
        });

        Route::get('/audit-logs', [AuditLogController::class, 'index'])
            ->middleware('admin.role:audit_logs.view')
            ->name('admin.audit-logs.index');

        // ── Dedicated Quiet Time Video management ────────────────────────────
        Route::prefix('quiet-time-videos')
            ->middleware('admin.role:quiet_time.manage')
            ->group(function (): void {
                Route::get('/', [QuietTimeVideoAdminController::class, 'index'])
                    ->name('admin.qt-videos.index');
                Route::get('/create', [QuietTimeVideoAdminController::class, 'create'])
                    ->name('admin.qt-videos.create');
                Route::post('/', [QuietTimeVideoAdminController::class, 'store'])
                    ->name('admin.qt-videos.store');
                Route::get('/{sessionId}/edit', [QuietTimeVideoAdminController::class, 'edit'])
                    ->name('admin.qt-videos.edit');
                Route::put('/{sessionId}', [QuietTimeVideoAdminController::class, 'update'])
                    ->name('admin.qt-videos.update');
                Route::post('/{sessionId}/upload', [QuietTimeVideoAdminController::class, 'upload'])
                    ->name('admin.qt-videos.upload');
                Route::post('/{sessionId}/publish', [QuietTimeVideoAdminController::class, 'publish'])
                    ->name('admin.qt-videos.publish');
                Route::delete('/{sessionId}', [QuietTimeVideoAdminController::class, 'destroy'])
                    ->name('admin.qt-videos.destroy');
            });

        Route::get('/{module}', [AdminModuleController::class, 'index'])
            ->where('module', '[A-Za-z0-9\-]+')
            ->name('admin.module.index');

        Route::get('/{module}/{id}', [AdminModuleController::class, 'show'])
            ->where('module', '[A-Za-z0-9\-]+')
            ->name('admin.module.show');

        Route::get('/{module}/{id}/edit', [AdminModuleController::class, 'edit'])
            ->where('module', '[A-Za-z0-9\-]+')
            ->name('admin.module.edit');

        Route::put('/{module}/{id}', [AdminModuleController::class, 'update'])
            ->where('module', '[A-Za-z0-9\-]+')
            ->name('admin.module.update');

        Route::post('/{module}', [AdminModuleController::class, 'store'])
            ->where('module', '[A-Za-z0-9\-]+')
            ->name('admin.module.store');

        Route::delete('/{module}/{id}', [AdminModuleController::class, 'destroy'])
            ->where('module', '[A-Za-z0-9\-]+')
            ->name('admin.module.destroy');

        Route::post('/{module}/bulk', [AdminModuleController::class, 'bulk'])
            ->where('module', '[A-Za-z0-9\-]+')
            ->name('admin.module.bulk');
    });
});
