begin;

create table if not exists public.partners (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  display_name text not null,
  handle text unique,
  email text,
  status text not null default 'active',
  public_bio text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint partners_status_check check (status in ('active', 'inactive'))
);

create table if not exists public.partner_links (
  id uuid primary key default gen_random_uuid(),
  partner_id uuid not null references public.partners(id) on delete cascade,
  slug text not null unique,
  destination_url text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.partner_clicks (
  id uuid primary key default gen_random_uuid(),
  partner_link_id uuid references public.partner_links(id) on delete set null,
  partner_id uuid references public.partners(id) on delete set null,
  slug text,
  referrer text,
  user_agent text,
  ip_hash text,
  clicked_at timestamptz not null default now()
);

create index if not exists partner_links_partner_id_idx
  on public.partner_links (partner_id);

create index if not exists partner_links_slug_active_idx
  on public.partner_links (slug, is_active);

create index if not exists partner_clicks_partner_id_idx
  on public.partner_clicks (partner_id);

create index if not exists partner_clicks_partner_link_id_idx
  on public.partner_clicks (partner_link_id);

create index if not exists partner_clicks_clicked_at_idx
  on public.partner_clicks (clicked_at desc);

alter table public.partners enable row level security;
alter table public.partner_links enable row level security;
alter table public.partner_clicks enable row level security;

revoke all on public.partners from anon, authenticated;
revoke all on public.partner_links from anon, authenticated;
revoke all on public.partner_clicks from anon, authenticated;

grant select on public.partners to authenticated;
grant select on public.partner_links to authenticated;
grant select on public.partner_clicks to authenticated;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_partners_updated_at on public.partners;

create trigger set_partners_updated_at
before update on public.partners
for each row
execute function public.set_updated_at();

drop policy if exists "partners can view own partner profile" on public.partners;
create policy "partners can view own partner profile"
on public.partners
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "partners can view own links" on public.partner_links;
create policy "partners can view own links"
on public.partner_links
for select
to authenticated
using (
  exists (
    select 1
    from public.partners
    where public.partners.id = public.partner_links.partner_id
      and public.partners.user_id = auth.uid()
  )
);

drop policy if exists "partners can view own clicks" on public.partner_clicks;
create policy "partners can view own clicks"
on public.partner_clicks
for select
to authenticated
using (
  exists (
    select 1
    from public.partners
    where public.partners.id = public.partner_clicks.partner_id
      and public.partners.user_id = auth.uid()
  )
);

commit;
