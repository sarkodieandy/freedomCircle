insert into public.recovery_categories (name, slug, icon, description, is_sensitive, sort_order)
values
  ('Screen Discipline', 'screen-discipline', 'phone-lock', 'Build healthier phone and media boundaries with supportive accountability.', true, 10),
  ('Prayer Discipline', 'prayer-discipline', 'hands-prayer', 'Grow a steady rhythm of personal prayer without shame or pressure.', false, 20),
  ('Fasting Discipline', 'fasting-discipline', 'flame', 'Track safe fasting commitments and reflections.', false, 30),
  ('Bible Study Consistency', 'bible-study-consistency', 'book-open', 'Stay consistent with Scripture reading and study notes.', false, 40),
  ('Anger Control', 'anger-control', 'self-control', 'Reflect on triggers, repair steps, and calm responses.', true, 50),
  ('General Accountability', 'general-accountability', 'users', 'Invite support around daily habits, choices, and spiritual growth.', false, 60),
  ('Recovery Support', 'recovery-support', 'shield-heart', 'Receive gentle support for recovery goals and resets.', true, 70),
  ('New Believer Growth', 'new-believer-growth', 'sprout', 'Build foundations in prayer, Scripture, fellowship, and discipleship.', false, 80)
on conflict (slug) do update
set
  name = excluded.name,
  icon = excluded.icon,
  description = excluded.description,
  is_sensitive = excluded.is_sensitive,
  sort_order = excluded.sort_order;

insert into public.groups (name, slug, description, group_type, visibility, weekly_prompt, is_premium, status)
values
  ('Men''s Accountability Circle', 'mens-accountability-circle', 'A moderated support circle for prayer, honesty, and weekly recovery check-ins.', 'accountability', 'public', 'What helped you stay steady this week?', false, 'active'),
  ('Women''s Bible Study', 'womens-bible-study', 'A gentle Bible study and encouragement circle for women.', 'bible_study', 'public', 'Which verse shaped your week?', false, 'active'),
  ('Students Fellowship', 'students-fellowship', 'Student-focused support for discipline, pressure, study rhythms, and faith.', 'fellowship', 'public', 'What choice do you want prayer for today?', false, 'active'),
  ('Prayer Discipline Group', 'prayer-discipline-group', 'Daily prayer rhythm, testimony, and encouragement.', 'prayer', 'public', 'What prayer habit are you practicing?', false, 'active'),
  ('Fasting Challenge', 'fasting-challenge', 'A safe, supportive fasting challenge space with reflection prompts.', 'fasting', 'premium', 'How are you preparing wisely?', true, 'active'),
  ('New Believers Class', 'new-believers-class', 'Foundations for Scripture, prayer, fellowship, and identity in Christ.', 'discipleship', 'public', 'What question are you carrying this week?', false, 'active'),
  ('Scripture Memorization Group', 'scripture-memorization-group', 'A community space for memorizing and applying Scripture.', 'bible_study', 'public', 'Which verse are you practicing?', false, 'active'),
  ('Recovery Support Circle', 'recovery-support-circle', 'A supportive recovery space focused on reflection, resets, and encouragement.', 'recovery', 'public', 'What support would help you today?', false, 'active')
on conflict (slug) do update
set
  description = excluded.description,
  group_type = excluded.group_type,
  visibility = excluded.visibility,
  weekly_prompt = excluded.weekly_prompt,
  is_premium = excluded.is_premium,
  status = excluded.status;

insert into public.app_content (key, title, body, content_type, sort_order)
values
  ('daily_verse_placeholder', 'Daily Verse', 'Add today''s Scripture verse from your approved content source.', 'daily_verse', 10),
  ('onboarding_welcome', 'Welcome to FreedomCircle', 'A private Christian support space for accountability, prayer, recovery, and steady growth.', 'onboarding', 20),
  ('premium_features', 'Premium Support', 'Unlock unlimited recovery plans, private journals, guided devotion paths, helper matching, and premium groups.', 'subscription_copy', 30),
  ('safety_disclaimer', 'Safety Notice', 'FreedomCircle offers faith-based support and accountability. It is not emergency, medical, legal, or clinical crisis care.', 'safety', 40)
on conflict (key) do update
set
  title = excluded.title,
  body = excluded.body,
  content_type = excluded.content_type,
  sort_order = excluded.sort_order,
  is_active = true,
  updated_at = now();

insert into public.app_settings (key, value, description)
values
  ('premium_weekly_price', '{"amount": 3, "currency": "USD"}', 'Weekly premium app plan price.'),
  ('premium_monthly_price', '{"amount": 10, "currency": "USD"}', 'Monthly premium app plan price.'),
  ('premium_yearly_price', '{"amount": 30, "currency": "USD"}', 'Yearly premium app plan price.'),
  ('premium_currency', '{"code": "USD"}', 'Default premium currency.'),
  ('recommended_plan', '{"code": "premium_yearly"}', 'Recommended premium plan code.'),
  ('yearly_best_value_enabled', '{"enabled": true}', 'Highlights yearly plan as best value.'),
  ('soft_upgrade_cards_enabled', '{"enabled": true}', 'Enable non-invasive upgrade cards.'),
  ('milestone_upgrade_prompt_enabled', '{"enabled": true}', 'Enable milestone-based prompts.'),
  ('church_starter_price', '{"amount": 199.00, "currency": "GHS"}', 'Starter church organization plan price.'),
  ('church_growth_price', '{"amount": 400.00, "currency": "GHS"}', 'Growth church organization plan price.'),
  ('church_pro_price', '{"amount": 800.00, "currency": "GHS"}', 'Pro church organization plan price.'),
  ('coach_commission_percentage', '{"percentage": 15}', 'Marketplace commission percentage for helper/coach bookings.'),
  ('coach_default_commission_percent', '{"percentage": 20}', 'Default platform commission for paid helper/coach bookings.'),
  ('paystack_fee_percent', '{"percentage": 1.95}', 'Configurable Paystack provider fee estimate.'),
  ('free_group_join_limit', '{"limit": 2}', 'Free user group join limit.'),
  ('free_recovery_goal_limit', '{"limit": 1}', 'Free user recovery goal limit.'),
  ('free_journal_entry_limit', '{"limit": 5}', 'Free user private journal entry limit.'),
  ('free_quiet_time_session_limit', '{"limit": 4}', 'Free user quiet time completion limit.'),
  ('free_advanced_insights', '{"enabled": false}', 'Free users cannot access advanced insights.'),
  ('free_premium_groups', '{"enabled": false}', 'Free users cannot access premium groups.'),
  ('free_helper_matching', '{"enabled": false}', 'Free users cannot use helper matching.'),
  ('free_guided_programs', '{"enabled": false}', 'Free users cannot access guided premium programs.'),
  ('premium_trial_days', '{"days": 7}', 'Premium trial duration.'),
  ('paywall_enabled', '{"enabled": true}', 'Feature flag for paywall prompts.'),
  ('paid_programs_enabled', '{"enabled": true}', 'Feature flag for paid program catalog.'),
  ('coach_marketplace_enabled', '{"enabled": true}', 'Feature flag for helper/coach marketplace.'),
  ('safety_disclaimer_text', '{"text": "FreedomCircle is not an emergency service. If someone is in immediate danger, contact local emergency services or a trusted leader right away."}', 'Safety copy shown near support and helper flows.')
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
  ('free', 'Free', 'Basic private accountability, prayer, community, and tracking.', 'user', 'free', 0, 'GHS', 0, 'manual', null, true, 10),
  ('premium_weekly', 'Premium Weekly', 'Try Premium for a week and unlock deeper support.', 'user', 'weekly', 3, 'USD', 0, 'revenuecat', 'freedomcircle_premium_weekly', true, 20),
  ('premium_monthly', 'Premium Monthly', 'Stay consistent with full monthly access.', 'user', 'monthly', 10, 'USD', 0, 'revenuecat', 'freedomcircle_premium_monthly', true, 30),
  ('premium_yearly', 'Premium Yearly', 'Best value for your full growth journey.', 'user', 'yearly', 30, 'USD', 0, 'revenuecat', 'freedomcircle_premium_yearly', true, 40),
  ('church_starter', 'Church Starter', 'Private church groups, announcements, prayer requests, and basic reports.', 'church', 'monthly', 150, 'GHS', 0, 'manual', null, true, 40),
  ('church_growth', 'Church Growth', 'Expanded member capacity, helper assignment, reports, events, and admin roles.', 'church', 'monthly', 400, 'GHS', 0, 'manual', null, true, 50),
  ('church_pro', 'Church Pro', 'Advanced reports, multiple admins, branded organization page, exports, and priority support.', 'church', 'monthly', 800, 'GHS', 0, 'manual', null, true, 60)
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
  feature_key,
  feature_name,
  feature_description,
  feature_limit,
  true
from public.plans p
join (
  values
    ('free', 'recovery_goals_basic', 'Basic recovery goals', 'Create a limited number of recovery goals.', 2),
    ('free', 'community_wall_access', 'Community wall', 'Read and participate in the community wall.', null),
    ('free', 'prayer_wall_access', 'Prayer wall', 'Create and pray for public prayer requests.', null),
    ('free', 'basic_journal_entries', 'Basic journal entries', 'Keep a limited private journal.', 10),
    ('free', 'basic_checkins', 'Basic check-ins', 'Track daily check-ins.', null),
    ('premium_weekly', 'premium_access', 'Premium access', 'Unlock premium features.', null),
    ('premium_monthly', 'recovery_goals_unlimited', 'Unlimited recovery goals', 'Create unlimited recovery goals.', null),
    ('premium_weekly', 'recovery_goals_unlimited', 'Unlimited recovery goals', 'Create unlimited recovery goals.', null),
    ('premium_weekly', 'advanced_recovery_insights', 'Advanced recovery insights', 'Unlock charts, trigger insights, and weekly reports.', null),
    ('premium_weekly', 'premium_groups', 'Premium groups', 'Join guided premium accountability circles.', null),
    ('premium_weekly', 'unlimited_journal', 'Unlimited journal', 'Keep unlimited private and locked journal entries.', null),
    ('premium_weekly', 'quiet_time_premium_library', 'Quiet Time premium library', 'Access full premium quiet time sessions.', null),
    ('premium_weekly', 'quiet_time_advanced_insights', 'Quiet Time advanced insights', 'Unlock deeper quiet time analytics.', null),
    ('premium_weekly', 'helper_matching', 'Helper matching', 'Get smart helper and coach recommendations.', null),
    ('premium_weekly', 'guided_programs', 'Guided programs', 'Access premium-included devotion and recovery programs.', null),
    ('premium_weekly', 'private_anonymous_controls', 'Private anonymous controls', 'Fine-tune identity and anonymous posting controls.', null),
    ('premium_weekly', 'milestone_badges', 'Milestone badges', 'Unlock milestone badges.', null),
    ('premium_weekly', 'advanced_streak_calendar', 'Advanced streak calendar', 'Unlock advanced streak analytics.', null),
    ('premium_weekly', 'priority_support_prompts', 'Priority support prompts', 'Unlock priority support prompts.', null),
    ('premium_monthly', 'premium_access', 'Premium access', 'Unlock premium features.', null),
    ('premium_monthly', 'advanced_recovery_insights', 'Advanced recovery insights', 'Unlock charts, trigger insights, and weekly reports.', null),
    ('premium_monthly', 'premium_groups', 'Premium groups', 'Join guided premium accountability circles.', null),
    ('premium_monthly', 'unlimited_journal', 'Unlimited journal', 'Keep unlimited private and locked journal entries.', null),
    ('premium_monthly', 'quiet_time_premium_library', 'Quiet Time premium library', 'Access full premium quiet time sessions.', null),
    ('premium_monthly', 'quiet_time_advanced_insights', 'Quiet Time advanced insights', 'Unlock deeper quiet time analytics.', null),
    ('premium_monthly', 'helper_matching', 'Helper matching', 'Get smart helper and coach recommendations.', null),
    ('premium_monthly', 'guided_programs', 'Guided programs', 'Access premium-included devotion and recovery programs.', null),
    ('premium_monthly', 'paid_program_access', 'Paid program access', 'Access purchased programs and premium-included guided content.', null),
    ('premium_monthly', 'private_anonymous_controls', 'Private anonymous controls', 'Fine-tune identity and anonymous posting controls.', null),
    ('premium_monthly', 'milestone_badges', 'Milestone badges', 'Unlock milestone badges.', null),
    ('premium_monthly', 'advanced_streak_calendar', 'Advanced streak calendar', 'Unlock advanced streak analytics.', null),
    ('premium_monthly', 'priority_support_prompts', 'Priority support prompts', 'Unlock priority support prompts.', null),
    ('premium_yearly', 'premium_access', 'Premium access', 'Unlock premium features.', null),
    ('premium_yearly', 'recovery_goals_unlimited', 'Unlimited recovery goals', 'Create unlimited recovery goals.', null),
    ('premium_yearly', 'advanced_recovery_insights', 'Advanced recovery insights', 'Unlock charts, trigger insights, and weekly reports.', null),
    ('premium_yearly', 'premium_groups', 'Premium groups', 'Join guided premium accountability circles.', null),
    ('premium_yearly', 'unlimited_journal', 'Unlimited journal', 'Keep unlimited private and locked journal entries.', null),
    ('premium_yearly', 'quiet_time_premium_library', 'Quiet Time premium library', 'Access full premium quiet time sessions.', null),
    ('premium_yearly', 'quiet_time_advanced_insights', 'Quiet Time advanced insights', 'Unlock deeper quiet time analytics.', null),
    ('premium_yearly', 'helper_matching', 'Helper matching', 'Get smart helper and coach recommendations.', null),
    ('premium_yearly', 'guided_programs', 'Guided programs', 'Access premium-included devotion and recovery programs.', null),
    ('premium_yearly', 'paid_program_access', 'Paid program access', 'Access purchased programs and premium-included guided content.', null),
    ('premium_yearly', 'private_anonymous_controls', 'Private anonymous controls', 'Fine-tune identity and anonymous posting controls.', null),
    ('premium_yearly', 'yearly_badge', 'Yearly supporter badge', 'Show a yearly supporter badge where appropriate.', null),
    ('premium_yearly', 'milestone_badges', 'Milestone badges', 'Unlock milestone badges.', null),
    ('premium_yearly', 'advanced_streak_calendar', 'Advanced streak calendar', 'Unlock advanced streak analytics.', null),
    ('premium_yearly', 'priority_support_prompts', 'Priority support prompts', 'Unlock priority support prompts.', null),
    ('church_starter', 'church_private_groups', 'Church private groups', 'Create limited private church groups.', 3),
    ('church_starter', 'church_member_management', 'Member management', 'Manage a starter church member list.', 100),
    ('church_starter', 'church_announcements', 'Announcements', 'Post announcements to church members.', null),
    ('church_starter', 'church_reports', 'Basic reports', 'See basic prayer and group reports.', null),
    ('church_growth', 'church_private_groups', 'More private groups', 'Create more church-only accountability groups.', 12),
    ('church_growth', 'church_member_management', 'Expanded members', 'Manage larger church communities.', 500),
    ('church_growth', 'church_reports', 'Group reports', 'View member check-in and group reports.', null),
    ('church_growth', 'church_announcements', 'Announcements', 'Post announcements to church members.', null),
    ('church_growth', 'church_admin_roles', 'Admin roles', 'Assign church admin roles.', 5),
    ('church_growth', 'coach_marketplace', 'Helper assignment', 'Assign helpers and coaches to members.', null),
    ('church_pro', 'church_private_groups', 'Premium church groups', 'Create premium church-only groups.', null),
    ('church_pro', 'church_member_management', 'High member limits', 'Manage larger organization accounts.', null),
    ('church_pro', 'church_reports', 'Advanced reports', 'Use advanced reports and exports.', null),
    ('church_pro', 'church_announcements', 'Announcements', 'Post announcements to church members.', null),
    ('church_pro', 'church_admin_roles', 'Multiple admins', 'Create multiple admin roles.', null),
    ('church_pro', 'coach_marketplace', 'Helper assignment', 'Assign helpers and coaches to members.', null),
    ('church_pro', 'custom_branding', 'Custom branding', 'Create a branded organization page.', null)
) as features(plan_code, feature_key, feature_name, feature_description, feature_limit)
  on p.code = features.plan_code
on conflict (plan_id, feature_key) do update
set
  feature_name = excluded.feature_name,
  feature_description = excluded.feature_description,
  feature_limit = excluded.feature_limit,
  is_enabled = excluded.is_enabled;

insert into public.paid_programs (
  title,
  slug,
  description,
  cover_image_url,
  program_type,
  price,
  currency,
  is_premium_included,
  status
)
values
  ('7-Day Discipline Plan', '7-day-discipline-plan', 'A short guided rhythm for prayer, reflection, and daily accountability.', 'https://images.unsplash.com/photo-1499750310107-5fef28a66643?auto=format&fit=crop&w=1200&q=80', 'general', 0, 'GHS', true, 'active'),
  ('21-Day Freedom Challenge', '21-day-freedom-challenge', 'A guided accountability challenge with recovery prompts and group reflection.', 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=1200&q=80', 'recovery', 45, 'GHS', true, 'active'),
  ('30-Day Recovery Support Plan', '30-day-recovery-support-plan', 'Daily recovery support prompts, relapse prevention reflections, and accountability check-ins.', 'https://images.unsplash.com/photo-1519834785169-98be25ec3f84?auto=format&fit=crop&w=1200&q=80', 'recovery', 50, 'GHS', false, 'active'),
  ('40-Day Fasting and Prayer Guide', '40-day-fasting-prayer-guide', 'A gentle devotional guide for fasting, prayer, and reflection.', 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80', 'fasting', 60, 'GHS', false, 'active'),
  ('Bible Consistency Plan', 'bible-consistency-plan', 'A practical study rhythm for Scripture reading, memory, and reflection.', 'https://images.unsplash.com/photo-1504052434569-70ad5836ab65?auto=format&fit=crop&w=1200&q=80', 'bible_study', 35, 'GHS', true, 'active'),
  ('Church Small Group Program Starter', 'church-small-group-program-starter', 'A church-created program template for private accountability circles and member check-ins.', 'https://images.unsplash.com/photo-1491438590914-bc09fcaaf77a?auto=format&fit=crop&w=1200&q=80', 'church', 75, 'GHS', false, 'active'),
  ('Helper Recovery Session Toolkit', 'helper-recovery-session-toolkit', 'A helper-created guided support toolkit for structured recovery conversations.', 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=1200&q=80', 'recovery', 80, 'GHS', false, 'active')
on conflict (slug) do update
set
  title = excluded.title,
  description = excluded.description,
  cover_image_url = excluded.cover_image_url,
  program_type = excluded.program_type,
  price = excluded.price,
  currency = excluded.currency,
  is_premium_included = excluded.is_premium_included,
  status = excluded.status,
  updated_at = now();

insert into public.program_modules (program_id, title, description, sort_order)
select
  pp.id,
  module_title,
  module_description,
  sort_order
from public.paid_programs pp
join (
  values
    ('7-day-discipline-plan', 'Start with clarity', 'Set a small daily rhythm and private reflection cue.', 10),
    ('21-day-freedom-challenge', 'Week 1: Awareness', 'Notice patterns, triggers, and moments of grace.', 10),
    ('21-day-freedom-challenge', 'Week 2: Accountability', 'Build support through check-ins and prayer.', 20),
    ('30-day-recovery-support-plan', 'Foundation and triggers', 'Map recovery goals, pressure points, and support responses.', 10),
    ('40-day-fasting-prayer-guide', 'Preparing wisely', 'Plan safe fasting rhythms with prayerful intention.', 10),
    ('bible-consistency-plan', 'Build the rhythm', 'Choose a simple Scripture plan and reflection cadence.', 10),
    ('church-small-group-program-starter', 'Launch the circle', 'Prepare prompts, member expectations, and reporting rhythms.', 10),
    ('helper-recovery-session-toolkit', 'Structured support', 'Use guided questions for safe, supportive helper conversations.', 10)
) as modules(program_slug, module_title, module_description, sort_order)
  on pp.slug = modules.program_slug
where not exists (
  select 1
  from public.program_modules existing
  where existing.program_id = pp.id
    and existing.title = modules.module_title
);

insert into public.program_lessons (
  module_id,
  title,
  content,
  lesson_type,
  duration_minutes,
  sort_order
)
select
  pm.id,
  lesson_title,
  lesson_content,
  lesson_type,
  duration_minutes,
  sort_order
from public.program_modules pm
join public.paid_programs pp on pp.id = pm.program_id
join (
  values
    ('7-day-discipline-plan', 'Start with clarity', 'Name one habit you want to strengthen and one support you need.', 'exercise', 8, 10),
    ('21-day-freedom-challenge', 'Week 1: Awareness', 'Write down the time, place, and feeling connected to your strongest trigger.', 'exercise', 10, 10),
    ('21-day-freedom-challenge', 'Week 2: Accountability', 'Choose one trusted circle check-in and share one honest sentence.', 'exercise', 10, 10),
    ('30-day-recovery-support-plan', 'Foundation and triggers', 'Name one pattern, one support person, and one healthy replacement action.', 'exercise', 10, 10),
    ('40-day-fasting-prayer-guide', 'Preparing wisely', 'Set a safe fasting window and write a prayer focus before you begin.', 'text', 7, 10),
    ('bible-consistency-plan', 'Build the rhythm', 'Choose a reading window and write one reflection question for the week.', 'exercise', 8, 10),
    ('church-small-group-program-starter', 'Launch the circle', 'Draft the first group prompt and member care expectation.', 'exercise', 12, 10),
    ('helper-recovery-session-toolkit', 'Structured support', 'Prepare three listening questions and one follow-up action.', 'exercise', 12, 10)
) as lessons(program_slug, module_title, lesson_title, lesson_content, lesson_type, duration_minutes, sort_order)
  on pp.slug = lessons.program_slug
  and pm.title = lessons.module_title
where not exists (
  select 1
  from public.program_lessons existing
  where existing.module_id = pm.id
    and existing.title = lessons.lesson_title
);
