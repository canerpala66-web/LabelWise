begin;

create table if not exists public.user_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  provider text not null default 'google_play',
  product_id text not null,
  purchase_token_hash text not null,
  status text not null,
  starts_at timestamptz,
  expires_at timestamptz,
  auto_renewing boolean,
  last_verified_at timestamptz,
  order_id text,
  base_plan_id text,
  environment text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_subscriptions_provider_check
    check (provider in ('google_play')),
  constraint user_subscriptions_status_check
    check (
      status in (
        'active',
        'expired',
        'canceled',
        'grace_period',
        'account_hold',
        'pending',
        'refunded',
        'unknown'
      )
    ),
  constraint user_subscriptions_environment_check
    check (
      environment is null
      or environment in ('sandbox', 'production')
    )
);

create unique index if not exists user_subscriptions_purchase_token_hash_key
  on public.user_subscriptions (purchase_token_hash);

create index if not exists user_subscriptions_user_id_idx
  on public.user_subscriptions (user_id);

create index if not exists user_subscriptions_status_idx
  on public.user_subscriptions (status);

create index if not exists user_subscriptions_expires_at_idx
  on public.user_subscriptions (expires_at);

create index if not exists user_subscriptions_provider_product_id_idx
  on public.user_subscriptions (provider, product_id);

alter table public.user_subscriptions enable row level security;

revoke all on public.user_subscriptions from anon, authenticated;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_user_subscriptions_updated_at
on public.user_subscriptions;

create trigger set_user_subscriptions_updated_at
before update on public.user_subscriptions
for each row
execute function public.set_updated_at();

commit;
