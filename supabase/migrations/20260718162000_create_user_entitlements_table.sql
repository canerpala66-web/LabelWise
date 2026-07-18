begin;

create table if not exists public.user_entitlements (
  user_id uuid primary key references auth.users(id) on delete cascade,
  is_premium boolean not null default false,
  plan_code text,
  entitlement_source text,
  valid_until timestamptz,
  updated_at timestamptz not null default now()
);

alter table public.user_entitlements enable row level security;

revoke all on public.user_entitlements from anon, authenticated;
grant select on public.user_entitlements to authenticated;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_user_entitlements_updated_at on public.user_entitlements;

create trigger set_user_entitlements_updated_at
before update on public.user_entitlements
for each row
execute function public.set_updated_at();

create or replace function public.handle_new_user_entitlement()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.user_entitlements (
    user_id,
    is_premium
  )
  values (
    new.id,
    false
  )
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_entitlement on auth.users;

create trigger on_auth_user_created_entitlement
after insert on auth.users
for each row
execute function public.handle_new_user_entitlement();

insert into public.user_entitlements (
  user_id,
  is_premium
)
select
  users.id,
  false
from auth.users as users
on conflict (user_id) do nothing;

drop policy if exists "users can view own entitlement" on public.user_entitlements;
drop policy if exists "users can insert own entitlement" on public.user_entitlements;
drop policy if exists "users can update own entitlement" on public.user_entitlements;
drop policy if exists "users can delete own entitlement" on public.user_entitlements;

create policy "users can view own entitlement"
on public.user_entitlements
for select
to authenticated
using (auth.uid() = user_id);

commit;
