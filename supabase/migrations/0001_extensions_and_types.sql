create extension if not exists "pgcrypto";
create extension if not exists "citext";

do $$
begin
  create type public.user_role as enum (
    'user',
    'helper',
    'coach',
    'pastor',
    'moderator',
    'church_admin',
    'admin',
    'super_admin'
  );
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.profile_status as enum ('active', 'suspended', 'deleted');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.privacy_level as enum ('private', 'anonymous', 'group', 'public');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.goal_status as enum ('active', 'paused', 'completed', 'archived');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.recovery_log_type as enum (
    'stayed_strong',
    'struggled',
    'reset',
    'milestone',
    'note'
  );
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.group_visibility as enum (
    'public',
    'private',
    'church_only',
    'premium',
    'invite_only'
  );
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.group_member_role as enum ('member', 'helper', 'moderator', 'owner');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.group_member_status as enum ('pending', 'approved', 'blocked', 'left');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.post_type as enum (
    'prayer_request',
    'testimony',
    'struggle',
    'encouragement',
    'question',
    'announcement'
  );
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.content_status as enum (
    'active',
    'pending_review',
    'hidden',
    'removed'
  );
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.reaction_type as enum ('pray', 'amen', 'encourage');
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.booking_status as enum (
    'requested',
    'accepted',
    'declined',
    'cancelled',
    'completed',
    'missed'
  );
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.payment_status as enum (
    'pending',
    'successful',
    'failed',
    'refunded',
    'cancelled'
  );
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.subscription_plan as enum (
    'free',
    'premium_monthly',
    'premium_yearly',
    'church_starter',
    'church_growth',
    'church_pro'
  );
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.subscription_status as enum (
    'active',
    'trialing',
    'past_due',
    'cancelled',
    'expired'
  );
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.report_status as enum (
    'open',
    'reviewing',
    'resolved',
    'dismissed'
  );
exception when duplicate_object then null;
end $$;

do $$
begin
  create type public.notification_type as enum (
    'prayer',
    'group',
    'chat',
    'helper',
    'milestone',
    'subscription',
    'safety',
    'system'
  );
exception when duplicate_object then null;
end $$;
