alter table public.plans
  add column if not exists provider text not null default 'manual',
  add column if not exists provider_product_id text;

alter table public.plans
  drop constraint if exists plans_billing_interval_check;

alter table public.plans
  add constraint plans_billing_interval_check
  check (billing_interval in ('free', 'weekly', 'monthly', 'yearly', 'one_time'))
  not valid;

alter table public.plans
  drop constraint if exists plans_provider_check;

alter table public.plans
  add constraint plans_provider_check
  check (provider in ('manual', 'revenuecat', 'paystack', 'app_store', 'google_play'))
  not valid;

insert into public.app_settings (key, value, description)
values
  ('free_recovery_goal_limit', '{"limit": 1}', 'Free user recovery goal limit.'),
  ('free_group_join_limit', '{"limit": 2}', 'Free user group join limit.'),
  ('free_journal_entry_limit', '{"limit": 5}', 'Free user private journal entry limit.'),
  ('free_quiet_time_session_limit', '{"limit": 4}', 'Free user quiet time completion limit before premium prompt.'),
  ('premium_weekly_price', '{"amount": 3, "currency": "USD"}', 'Weekly premium plan price.'),
  ('premium_monthly_price', '{"amount": 10, "currency": "USD"}', 'Monthly premium plan price.'),
  ('premium_yearly_price', '{"amount": 30, "currency": "USD"}', 'Yearly premium plan price.'),
  ('premium_currency', '{"code": "USD"}', 'Default premium price currency.'),
  ('recommended_plan', '{"code": "premium_yearly"}', 'Default recommended premium plan.'),
  ('yearly_best_value_enabled', '{"enabled": true}', 'Enable yearly best value badge.'),
  ('paywall_enabled', '{"enabled": true}', 'Enable contextual paywall prompts.'),
  ('soft_upgrade_cards_enabled', '{"enabled": true}', 'Enable soft upgrade cards for free users.'),
  ('milestone_upgrade_prompt_enabled', '{"enabled": true}', 'Enable milestone based premium prompts.')
on conflict (key) do update
set
  value = excluded.value,
  description = excluded.description,
  updated_at = now();

insert into public.plans (
  code,
  name,
  description,
  plan_type,
  billing_interval,
  price,
  currency,
  trial_days,
  provider,
  provider_product_id,
  is_active,
  sort_order
)
values
  ('premium_weekly', 'Premium Weekly', 'Try Premium for a week and unlock deeper support.', 'user', 'weekly', 3, 'USD', 0, 'revenuecat', 'freedomcircle_premium_weekly', true, 20),
  ('premium_monthly', 'Premium Monthly', 'Stay consistent with full monthly access.', 'user', 'monthly', 10, 'USD', 0, 'revenuecat', 'freedomcircle_premium_monthly', true, 30),
  ('premium_yearly', 'Premium Yearly', 'Best value for your full growth journey.', 'user', 'yearly', 30, 'USD', 0, 'revenuecat', 'freedomcircle_premium_yearly', true, 40)
on conflict (code) do update
set
  name = excluded.name,
  description = excluded.description,
  plan_type = excluded.plan_type,
  billing_interval = excluded.billing_interval,
  price = excluded.price,
  currency = excluded.currency,
  trial_days = excluded.trial_days,
  provider = excluded.provider,
  provider_product_id = excluded.provider_product_id,
  is_active = excluded.is_active,
  sort_order = excluded.sort_order,
  updated_at = now();

create index if not exists idx_plans_provider_product on public.plans (provider, provider_product_id);

insert into public.plan_features (
  plan_id,
  feature_key,
  feature_name,
  feature_description,
  feature_limit,
  is_enabled
)
select
  p.id,
  f.feature_key,
  f.feature_name,
  f.feature_description,
  f.feature_limit,
  true
from public.plans p
join (
  values
    ('premium_weekly', 'premium_access', 'Premium access', 'Unlock premium features.', null),
    ('premium_weekly', 'recovery_goals_unlimited', 'Unlimited recovery goals', 'Create unlimited recovery goals.', null),
    ('premium_weekly', 'advanced_recovery_insights', 'Advanced recovery insights', 'Unlock deeper growth insights.', null),
    ('premium_weekly', 'premium_groups', 'Premium groups', 'Join guided accountability groups.', null),
    ('premium_weekly', 'unlimited_journal', 'Unlimited private journal', 'Create unlimited journal entries.', null),
    ('premium_weekly', 'quiet_time_premium_library', 'Quiet Time premium library', 'Unlock full quiet time sessions.', null),
    ('premium_weekly', 'quiet_time_advanced_insights', 'Quiet Time advanced insights', 'Unlock quiet time progress insights.', null),
    ('premium_weekly', 'helper_matching', 'Helper matching', 'Get smarter helper recommendations.', null),
    ('premium_weekly', 'guided_programs', 'Guided programs', 'Access guided devotion and recovery programs.', null),
    ('premium_weekly', 'private_anonymous_controls', 'Premium privacy controls', 'Enhanced privacy and anonymous controls.', null),
    ('premium_weekly', 'milestone_badges', 'Milestone badges', 'Unlock milestone badges.', null),
    ('premium_weekly', 'advanced_streak_calendar', 'Advanced streak calendar', 'Unlock detailed streak analytics.', null),
    ('premium_weekly', 'priority_support_prompts', 'Priority support prompts', 'Get priority support prompts.', null),

    ('premium_monthly', 'premium_access', 'Premium access', 'Unlock premium features.', null),
    ('premium_monthly', 'recovery_goals_unlimited', 'Unlimited recovery goals', 'Create unlimited recovery goals.', null),
    ('premium_monthly', 'advanced_recovery_insights', 'Advanced recovery insights', 'Unlock deeper growth insights.', null),
    ('premium_monthly', 'premium_groups', 'Premium groups', 'Join guided accountability groups.', null),
    ('premium_monthly', 'unlimited_journal', 'Unlimited private journal', 'Create unlimited journal entries.', null),
    ('premium_monthly', 'quiet_time_premium_library', 'Quiet Time premium library', 'Unlock full quiet time sessions.', null),
    ('premium_monthly', 'quiet_time_advanced_insights', 'Quiet Time advanced insights', 'Unlock quiet time progress insights.', null),
    ('premium_monthly', 'helper_matching', 'Helper matching', 'Get smarter helper recommendations.', null),
    ('premium_monthly', 'guided_programs', 'Guided programs', 'Access guided devotion and recovery programs.', null),
    ('premium_monthly', 'private_anonymous_controls', 'Premium privacy controls', 'Enhanced privacy and anonymous controls.', null),
    ('premium_monthly', 'milestone_badges', 'Milestone badges', 'Unlock milestone badges.', null),
    ('premium_monthly', 'advanced_streak_calendar', 'Advanced streak calendar', 'Unlock detailed streak analytics.', null),
    ('premium_monthly', 'priority_support_prompts', 'Priority support prompts', 'Get priority support prompts.', null),

    ('premium_yearly', 'premium_access', 'Premium access', 'Unlock premium features.', null),
    ('premium_yearly', 'recovery_goals_unlimited', 'Unlimited recovery goals', 'Create unlimited recovery goals.', null),
    ('premium_yearly', 'advanced_recovery_insights', 'Advanced recovery insights', 'Unlock deeper growth insights.', null),
    ('premium_yearly', 'premium_groups', 'Premium groups', 'Join guided accountability groups.', null),
    ('premium_yearly', 'unlimited_journal', 'Unlimited private journal', 'Create unlimited journal entries.', null),
    ('premium_yearly', 'quiet_time_premium_library', 'Quiet Time premium library', 'Unlock full quiet time sessions.', null),
    ('premium_yearly', 'quiet_time_advanced_insights', 'Quiet Time advanced insights', 'Unlock quiet time progress insights.', null),
    ('premium_yearly', 'helper_matching', 'Helper matching', 'Get smarter helper recommendations.', null),
    ('premium_yearly', 'guided_programs', 'Guided programs', 'Access guided devotion and recovery programs.', null),
    ('premium_yearly', 'private_anonymous_controls', 'Premium privacy controls', 'Enhanced privacy and anonymous controls.', null),
    ('premium_yearly', 'milestone_badges', 'Milestone badges', 'Unlock milestone badges.', null),
    ('premium_yearly', 'advanced_streak_calendar', 'Advanced streak calendar', 'Unlock detailed streak analytics.', null),
    ('premium_yearly', 'priority_support_prompts', 'Priority support prompts', 'Get priority support prompts.', null)
) as f(plan_code, feature_key, feature_name, feature_description, feature_limit)
  on p.code = f.plan_code
on conflict (plan_id, feature_key) do update
set
  feature_name = excluded.feature_name,
  feature_description = excluded.feature_description,
  feature_limit = excluded.feature_limit,
  is_enabled = excluded.is_enabled;
