<?php

namespace App\Http\Controllers\Admin;

use App\Models\AdminUser;
use App\Services\AppSettingsService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Validation\ValidationException;
use Illuminate\View\View;

class AppSettingsController extends Controller
{
    public function __construct(private readonly AppSettingsService $settings)
    {
    }

    public function index(): View
    {
        $groups = [];
        foreach (config('admin.settings_groups', []) as $group) {
            $groups[$group] = $this->settings->getGroup((string) $group);
        }

        return view('admin.settings.index', [
            'groups' => $groups,
        ]);
    }

    public function updateGroup(string $group, Request $request): RedirectResponse
    {
        $admin = $this->adminFromRequest($request);
        $payload = $request->validate([
            'settings' => ['required', 'array'],
        ]);

        try {
            $this->settings->updateGroup($group, $payload['settings'], $admin);
        } catch (\InvalidArgumentException $exception) {
            throw ValidationException::withMessages([
                'settings' => $exception->getMessage(),
            ]);
        }

        return back()->with('status', 'Settings updated successfully.');
    }

    public function reset(string $key, Request $request): RedirectResponse
    {
        $admin = $this->adminFromRequest($request);
        $result = $this->settings->resetToDefault($key, $admin);

        if ($result === null) {
            return back()->withErrors(['settings' => 'No default configured for this setting.']);
        }

        return back()->with('status', 'Setting reset to default.');
    }

    private function adminFromRequest(Request $request): AdminUser
    {
        $admin = $request->attributes->get('admin_user');
        if (! $admin instanceof AdminUser) {
            abort(401, 'Admin user context missing.');
        }

        return $admin;
    }
}
