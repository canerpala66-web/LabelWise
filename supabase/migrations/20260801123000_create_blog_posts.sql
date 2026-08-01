begin;

create table if not exists public.blog_posts (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  slug text not null,
  excerpt text,
  content_markdown text not null,
  cover_image_url text,
  category text,
  tags text[] not null default '{}',
  seo_title text,
  seo_description text,
  status text not null default 'draft',
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  constraint blog_posts_slug_key unique (slug),
  constraint blog_posts_status_check check (status in ('draft', 'published'))
);

create index if not exists blog_posts_status_idx
  on public.blog_posts (status);

create index if not exists blog_posts_published_at_idx
  on public.blog_posts (published_at desc nulls last);

create index if not exists blog_posts_category_idx
  on public.blog_posts (category);

alter table public.blog_posts enable row level security;

revoke all on public.blog_posts from anon, authenticated;
grant select on public.blog_posts to anon, authenticated;
grant insert, update, delete on public.blog_posts to authenticated;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_blog_posts_updated_at on public.blog_posts;

create trigger set_blog_posts_updated_at
before update on public.blog_posts
for each row
execute function public.set_updated_at();

drop policy if exists "public can view published blog posts" on public.blog_posts;
create policy "public can view published blog posts"
on public.blog_posts
for select
to anon, authenticated
using (status = 'published');

drop policy if exists "admin users can manage blog posts" on public.blog_posts;
create policy "admin users can manage blog posts"
on public.blog_posts
for all
to authenticated
using (
  exists (
    select 1
    from public.admin_users
    where public.admin_users.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.admin_users
    where public.admin_users.user_id = auth.uid()
  )
);

commit;
