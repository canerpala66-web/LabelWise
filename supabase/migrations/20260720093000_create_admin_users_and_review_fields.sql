begin;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text,
  created_at timestamptz not null default now()
);

alter table public.admin_users enable row level security;

revoke all on public.admin_users from anon, authenticated;

alter table public.submitted_products
  add column if not exists status text default 'pending';

alter table public.submitted_products
  add column if not exists reviewed_at timestamptz;

alter table public.submitted_products
  add column if not exists review_note text;

alter table public.submitted_products
  add column if not exists reviewed_by uuid references auth.users(id) on delete set null;

create index if not exists submitted_products_status_idx
  on public.submitted_products (status);

create index if not exists submitted_products_reviewed_by_idx
  on public.submitted_products (reviewed_by);

commit;
