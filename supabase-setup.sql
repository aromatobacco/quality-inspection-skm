-- Jalankan di SQL Editor pada project Supabase BARU khusus SKM.
-- Akun SKT tidak otomatis memperoleh akses ke project ini.

create table if not exists public.skm_members (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (length(trim(display_name)) between 1 and 80),
  role text not null check (role in ('ADMIN', 'QC', 'VIEWER')),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.skm_inspections (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references auth.users(id) on delete restrict,
  station text not null check (station in ('Maker', 'Packer')),
  sample_date date not null,
  sample_time time without time zone not null
    check (extract(minute from sample_time) = 0 and extract(second from sample_time) = 0),
  qc_name text not null check (length(trim(qc_name)) between 1 and 60),
  shift text not null check (shift in ('Shift 1', 'Shift 2', 'Shift 3')),
  brand text not null check (brand in ('AMB', 'AMT', 'ARM', 'ARB12', 'ARB16')),
  machine text not null check (
    (station = 'Maker' and machine in ('M1','M2','M3','M4','M5')) or
    (station = 'Packer' and machine in ('P1','P2','P3','P4','P5','P6','Focke'))
  ),
  sample_count integer not null check (sample_count between 1 and 10000),
  physical jsonb not null default '{}'::jsonb check (jsonb_typeof(physical) = 'object'),
  visual jsonb not null default '{}'::jsonb check (jsonb_typeof(visual) = 'object'),
  no_finding boolean not null default false,
  trouble_point text not null default '' check (length(trouble_point) <= 500),
  notes text not null default '' check (length(notes) <= 500),
  production_code text not null default '' check (length(production_code) <= 100),
  cigarettes_per_pack integer check (cigarettes_per_pack is null or cigarettes_per_pack >= 0),
  pack_count integer check (pack_count is null or pack_count >= 0),
  created_at timestamptz not null default now()
);

create index if not exists skm_inspections_date_time_idx
  on public.skm_inspections (sample_date desc, sample_time desc);
create index if not exists skm_inspections_author_idx
  on public.skm_inspections (author_id);

alter table public.skm_members enable row level security;
alter table public.skm_inspections enable row level security;

-- Browser hanya menerima hak tabel yang diperlukan. Anon tidak menerima akses.
revoke all on table public.skm_members, public.skm_inspections from anon, authenticated;
grant usage on schema public to authenticated;
grant select on public.skm_members to authenticated;
grant select, insert, delete on public.skm_inspections to authenticated;

drop policy if exists skm_members_read_self on public.skm_members;
create policy skm_members_read_self on public.skm_members
  for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists skm_inspections_read_member on public.skm_inspections;
create policy skm_inspections_read_member on public.skm_inspections
  for select to authenticated
  using (exists (
    select 1 from public.skm_members m
    where m.user_id = (select auth.uid()) and m.is_active
  ));

drop policy if exists skm_inspections_insert_qc on public.skm_inspections;
create policy skm_inspections_insert_qc on public.skm_inspections
  for insert to authenticated
  with check (
    author_id = (select auth.uid()) and exists (
      select 1 from public.skm_members m
      where m.user_id = (select auth.uid()) and m.is_active
        and m.role in ('ADMIN', 'QC')
    )
  );

drop policy if exists skm_inspections_delete_author_or_admin on public.skm_inspections;
create policy skm_inspections_delete_author_or_admin on public.skm_inspections
  for delete to authenticated
  using (exists (
    select 1 from public.skm_members m
    where m.user_id = (select auth.uid()) and m.is_active
      and (m.role = 'ADMIN' or (m.role = 'QC' and author_id = (select auth.uid())))
  ));

-- Tambahkan anggota melalui SQL Editor setelah membuat akun di Authentication > Users.
-- Contoh perintah yang perlu disesuaikan ada di README.md.
