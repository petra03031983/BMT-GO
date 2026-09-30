-- BMT GO v17: protected admin courier review
-- Admins are identified by profiles.role = 'admin'.

alter table public.courier_profiles enable row level security;

-- Admins can read applications; couriers keep access to their own row.
drop policy if exists courier_profiles_select_admin on public.courier_profiles;
create policy courier_profiles_select_admin on public.courier_profiles
for select to authenticated
using (
  auth.uid() = id
  or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
);

create or replace function public.review_courier(
  p_courier_id uuid,
  p_status text,
  p_reason text default null
)
returns public.courier_profiles
language plpgsql
security definer
set search_path = public
as $$
declare result public.courier_profiles;
begin
  if not exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin') then
    raise exception 'admin_only';
  end if;
  if p_status not in ('approved','rejected','blocked','pending') then
    raise exception 'invalid_status';
  end if;

  update public.courier_profiles
  set status = p_status,
      rejection_reason = case when p_status = 'rejected' then nullif(trim(coalesce(p_reason,'')),'') else null end,
      updated_at = now()
  where id = p_courier_id
  returning * into result;

  if result.id is null then raise exception 'courier_not_found'; end if;
  return result;
end;
$$;

revoke all on function public.review_courier(uuid,text,text) from public;
grant execute on function public.review_courier(uuid,text,text) to authenticated;
