-- ==============================================================================
-- Migration: 20260828020000_chat_security_and_trigger_integrity.sql
-- Description:
-- 1. Fix DB trigger authorization logic in enforce_profile_integrity() and
--    enforce_property_integrity() to allow backend service-role / superuser operations (where auth.uid() is null).
-- 2. Add enforce_message_integrity() trigger on public.messages to prevent tampering
--    with sender_id, message_text, conversation_id, message_type, and created_at on updates.
-- ==============================================================================

-- 1. Update enforce_profile_integrity() to permit service-role / admin updates
create or replace function public.enforce_profile_integrity()
returns trigger
language plpgsql
security definer
as $$
begin
  -- Allow backend service-role, direct SQL sessions, or admin users to update profiles freely
  if auth.uid() is null or
     coalesce(current_setting('request.jwt.claim.role', true), '') = 'service_role' or
     exists (select 1 from public.profiles where auth_user_id = auth.uid() and role = 'admin') then
    return new;
  end if;

  -- Prevent non-admin users from escalating their role
  if new.role is distinct from old.role then
    new.role := old.role;
  end if;

  -- Prevent tampering with auth binding or primary email
  new.auth_user_id := old.auth_user_id;
  new.email := old.email;
  
  return new;
end;
$$;

drop trigger if exists check_profile_integrity on public.profiles;
create trigger check_profile_integrity
before update on public.profiles
for each row execute function public.enforce_profile_integrity();

-- 2. Update enforce_property_integrity() to permit service-role / admin updates
create or replace function public.enforce_property_integrity()
returns trigger
language plpgsql
security definer
as $$
begin
  -- Allow backend service-role, direct SQL sessions, or admin users to update properties freely
  if auth.uid() is null or
     coalesce(current_setting('request.jwt.claim.role', true), '') = 'service_role' or
     exists (select 1 from public.profiles where auth_user_id = auth.uid() and role = 'admin') then
    return new;
  end if;

  -- If a non-admin modifies property details or attempts to approve a property, force status to pending
  if (new.status is distinct from old.status and new.status = 'approved') or
     (new.name is distinct from old.name) or
     (new.price is distinct from old.price) or
     (new.description is distinct from old.description) or
     (new.location is distinct from old.location) or
     (new.image_path is distinct from old.image_path) or
     (new.model_path is distinct from old.model_path) then
    new.status := 'pending';
  end if;

  -- Non-admins cannot modify featured flag or transfer ownership
  new.is_featured := old.is_featured;
  new.homeowner_id := old.homeowner_id;

  return new;
end;
$$;

drop trigger if exists check_property_integrity on public.properties;
create trigger check_property_integrity
before update on public.properties
for each row execute function public.enforce_property_integrity();

-- 3. Create enforce_message_integrity() trigger function on public.messages
create or replace function public.enforce_message_integrity()
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

  -- Ensure critical message columns are immutable for normal clients
  new.id := old.id;
  new.conversation_id := old.conversation_id;
  new.sender_id := old.sender_id;
  new.message_text := old.message_text;
  new.message_type := old.message_type;
  new.created_at := old.created_at;

  return new;
end;
$$;

drop trigger if exists check_message_integrity on public.messages;
create trigger check_message_integrity
before update on public.messages
for each row execute function public.enforce_message_integrity();
