begin;

alter table public.profiles
  add column if not exists age integer,
  add column if not exists gender text,
  add column if not exists height_cm integer,
  add column if not exists weight_kg numeric(5, 1);

alter table public.profiles
  drop constraint if exists profiles_age_check,
  drop constraint if exists profiles_gender_check,
  drop constraint if exists profiles_height_cm_check,
  drop constraint if exists profiles_weight_kg_check;

alter table public.profiles
  add constraint profiles_age_check
    check (age is null or (age >= 0 and age <= 120)),
  add constraint profiles_gender_check
    check (
      gender is null
      or lower(gender) in ('kadın', 'erkek', 'belirtmek istemiyorum')
    ),
  add constraint profiles_height_cm_check
    check (height_cm is null or (height_cm >= 50 and height_cm <= 300)),
  add constraint profiles_weight_kg_check
    check (weight_kg is null or (weight_kg > 0 and weight_kg <= 500));

commit;
