begin;

alter table public.products
  add column if not exists quantity_value numeric,
  add column if not exists quantity_unit text,
  add column if not exists serving_size text,
  add column if not exists energy_kj numeric,
  add column if not exists sodium numeric,
  add column if not exists data_source text,
  add column if not exists source_url text,
  add column if not exists data_updated_at timestamptz,
  add column if not exists packaging_version text,
  add column if not exists is_current boolean,
  add column if not exists verification_notes text,
  add column if not exists country text,
  add column if not exists language_code text,
  add column if not exists external_id text,
  add column if not exists notes text,
  add column if not exists is_verified boolean;

create table if not exists public.product_import_jobs (
  id uuid primary key default gen_random_uuid(),
  file_name text not null,
  file_type text not null,
  file_size bigint not null,
  status text not null default 'uploaded',
  import_mode text not null,
  allow_stale_override boolean not null default false,
  confirmation_key text not null,
  total_rows integer not null default 0,
  valid_rows integer not null default 0,
  warning_rows integer not null default 0,
  invalid_rows integer not null default 0,
  inserted_rows integer not null default 0,
  updated_rows integer not null default 0,
  skipped_rows integer not null default 0,
  failed_rows integer not null default 0,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  confirmed_at timestamptz,
  completed_at timestamptz,
  error_message text,
  constraint product_import_jobs_status_check
    check (
      status in (
        'uploaded',
        'validating',
        'ready',
        'importing',
        'completed',
        'partially_completed',
        'failed',
        'cancelled'
      )
    ),
  constraint product_import_jobs_import_mode_check
    check (
      import_mode in (
        'insert_and_update',
        'insert_only',
        'update_only'
      )
    ),
  constraint product_import_jobs_confirmation_key_unique
    unique (created_by, confirmation_key)
);

create index if not exists product_import_jobs_created_by_idx
  on public.product_import_jobs (created_by, created_at desc);

create index if not exists product_import_jobs_status_idx
  on public.product_import_jobs (status, created_at desc);

create table if not exists public.product_import_rows (
  id uuid primary key default gen_random_uuid(),
  import_job_id uuid not null references public.product_import_jobs(id) on delete cascade,
  row_number integer not null,
  barcode text,
  normalized_data jsonb not null default '{}'::jsonb,
  validation_errors jsonb not null default '[]'::jsonb,
  validation_warnings jsonb not null default '[]'::jsonb,
  status text not null,
  existing_product_id text,
  imported_product_id text,
  created_at timestamptz not null default now(),
  processed_at timestamptz
);

create index if not exists product_import_rows_job_idx
  on public.product_import_rows (import_job_id, row_number);

create index if not exists product_import_rows_status_idx
  on public.product_import_rows (import_job_id, status);

alter table public.product_import_jobs enable row level security;
alter table public.product_import_rows enable row level security;

revoke all on public.product_import_jobs from anon, authenticated;
revoke all on public.product_import_rows from anon, authenticated;

drop trigger if exists set_product_import_jobs_updated_at on public.product_import_jobs;

commit;
