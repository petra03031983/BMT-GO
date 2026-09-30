-- BMT GO v33 — account deletion requests
create table if not exists public.account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','processing','completed','rejected')),
  reason text,
  requested_at timestamptz not null default now(),
  processed_at timestamptz,
  processed_by uuid references auth.users(id)
);

create index if not exists idx_account_deletion_requests_user on public.account_deletion_requests(user_id);
create index if not exists idx_account_deletion_requests_status on public.account_deletion_requests(status);

alter table public.account_deletion_requests enable row level security;

drop policy if exists "users can view own deletion requests" on public.account_deletion_requests;
create policy "users can view own deletion requests"
on public.account_deletion_requests for select
to authenticated using (user_id = auth.uid());

create or replace function public.request_account_deletion()
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  if exists (select 1 from public.account_deletion_requests where user_id=auth.uid() and status in ('pending','processing')) then
    select id into v_id from public.account_deletion_requests where user_id=auth.uid() and status in ('pending','processing') order by requested_at desc limit 1;
    return v_id;
  end if;
  insert into public.account_deletion_requests(user_id) values(auth.uid()) returning id into v_id;
  return v_id;
end;
$$;
revoke all on function public.request_account_deletion() from public;
grant execute on function public.request_account_deletion() to authenticated;

-- Admin processing example. Complete account deletion should be performed only after
-- verifying retention obligations (payments, tax/accounting records, disputes, etc.).
-- Do not automatically delete auth.users from a client-side function.
