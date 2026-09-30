-- BMT GO v16: courier onboarding / verification
create table if not exists public.courier_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  transport_type text not null default 'car' check (transport_type in ('car','motorbike','bicycle','foot')),
  vehicle_brand text,
  vehicle_number text,
  license_number text,
  id_document_number text,
  document_photo_path text,
  vehicle_photo_path text,
  status text not null default 'pending' check (status in ('pending','approved','rejected','blocked')),
  rejection_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.courier_profiles enable row level security;
drop policy if exists courier_profiles_select_own on public.courier_profiles;
drop policy if exists courier_profiles_insert_own on public.courier_profiles;
drop policy if exists courier_profiles_update_own on public.courier_profiles;
create policy courier_profiles_select_own on public.courier_profiles for select using (auth.uid()=id);
create policy courier_profiles_insert_own on public.courier_profiles for insert with check (auth.uid()=id);
create policy courier_profiles_update_own on public.courier_profiles for update using (auth.uid()=id) with check (auth.uid()=id);

create or replace function public.touch_courier_profile_updated_at()
returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end; $$;
drop trigger if exists courier_profiles_updated_at on public.courier_profiles;
create trigger courier_profiles_updated_at before update on public.courier_profiles for each row execute function public.touch_courier_profile_updated_at();

-- Admin review is intentionally not exposed through the client policies.
-- Change status server-side or from a protected admin backend.

insert into storage.buckets (id, name, public) values ('courier-documents','courier-documents',false)
on conflict (id) do nothing;

alter table storage.objects enable row level security;
drop policy if exists courier_documents_insert_own on storage.objects;
drop policy if exists courier_documents_select_own on storage.objects;
create policy courier_documents_insert_own on storage.objects
for insert to authenticated
with check (bucket_id='courier-documents' and (storage.foldername(name))[1]=auth.uid()::text);
create policy courier_documents_select_own on storage.objects
for select to authenticated
using (bucket_id='courier-documents' and (storage.foldername(name))[1]=auth.uid()::text);
