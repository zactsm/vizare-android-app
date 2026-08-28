-- ==============================================================================
-- Migration: 20260828030000_security_and_compliance_hardening.sql
-- Description:
-- 1. SEC-01: Harden handle_new_auth_user() trigger against auth_user_id overwrites/account takeover.
-- 2. SEC-02: Enable RLS on public.property_types with public read & admin-only write policies.
-- 3. SEC-03: Add enforce_conversation_integrity() trigger on public.conversations to prevent participant tampering.
-- 4. SEC-09: Harden public.audit_logs insert RLS policy to bind actor_id, actor_email, and actor_role to authenticated profile.
-- ==============================================================================

-- 1. SEC-01: Update handle_new_auth_user() to prevent hijacking existing profiles
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (
    auth_user_id, email, full_name, role, has_password
  )
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name', 'User'),
    case new.raw_user_meta_data ->> 'role'
      when 'homeowner' then 'homeowner'::public.user_role
      else 'homebuyer'::public.user_role
    end,
    coalesce((new.raw_user_meta_data ->> 'has_password')::boolean, false)
  )
  on conflict (email) do update
  set auth_user_id = coalesce(public.profiles.auth_user_id, excluded.auth_user_id),
      full_name = coalesce(public.profiles.full_name, excluded.full_name),
      updated_at = now()
  where public.profiles.auth_user_id is null;
  return new;
end;
$$;

-- 2. SEC-02: Enable RLS & policies on property_types
alter table public.property_types enable row level security;

drop policy if exists "Anyone can read property types" on public.property_types;
create policy "Anyone can read property types"
  on public.property_types
  for select
  using (true);

drop policy if exists "Admins can manage property types" on public.property_types;
create policy "Admins can manage property types"
  on public.property_types
  for all
  using (
    exists (
      select 1 from public.profiles
      where profiles.auth_user_id = auth.uid()
        and profiles.role = 'admin'
    )
  );

-- 3. SEC-03: Add enforce_conversation_integrity() trigger function and trigger
create or replace function public.enforce_conversation_integrity()
returns trigger
language plpgsql
security definer
as $$
begin
  -- Allow backend service-role, direct SQL sessions, or admin users to perform unrestricted updates if needed
  if auth.uid() is null or
     coalesce(current_setting('request.jwt.claim.role', true), '') = 'service_role' or
     exists (select 1 from public.profiles where auth_user_id = auth.uid() and role = 'admin') then
    return new;
  end if;

  -- Ensure conversation participants and property cannot be tampered with on update
  new.id := old.id;
  new.property_id := old.property_id;
  new.buyer_id := old.buyer_id;
  new.homeowner_id := old.homeowner_id;
  new.created_at := old.created_at;

  return new;
end;
$$;

drop trigger if exists check_conversation_integrity on public.conversations;
create trigger check_conversation_integrity
before update on public.conversations
for each row execute function public.enforce_conversation_integrity();

-- 4. SEC-09: Update audit_logs insert RLS policy
drop policy if exists "Authenticated users can create audit logs" on public.audit_logs;
create policy "Authenticated users can create audit logs"
  on public.audit_logs
  for insert to authenticated
  with check (
    exists (
      select 1 from public.profiles
      where auth_user_id = auth.uid()
        and id = actor_id
        and email = actor_email
        and role = actor_role
    )
  );
