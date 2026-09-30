-- BMT GO v15: profiles + phone auth support
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  phone text,
  full_name text,
  role text not null default 'client' check (role in ('client','courier','admin')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
drop policy if exists profiles_select_own on public.profiles;
drop policy if exists profiles_insert_own on public.profiles;
drop policy if exists profiles_update_own on public.profiles;
create policy profiles_select_own on public.profiles for select using (auth.uid()=id);
create policy profiles_insert_own on public.profiles for insert with check (auth.uid()=id);
create policy profiles_update_own on public.profiles for update using (auth.uid()=id) with check (auth.uid()=id);

-- Important: do not allow the public client app to promote itself to admin.
-- In production, admin role should be assigned manually/server-side.
create or replace function public.protect_profile_role()
returns trigger language plpgsql security definer as $$
begin
  if auth.uid() = new.id and tg_op='UPDATE' and old.role='admin' and new.role<>'admin' then
    raise exception 'admin role cannot be changed from the client';
  end if;
  if auth.uid() = new.id and tg_op='UPDATE' and old.role<>'admin' and new.role='admin' then
    raise exception 'admin role cannot be assigned from the client';
  end if;
  return new;
end; $$;
drop trigger if exists protect_profile_role on public.profiles;
create trigger protect_profile_role before update on public.profiles for each row execute function public.protect_profile_role();
