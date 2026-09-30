-- BMT GO v24: courier earnings and payout requests
create table if not exists public.courier_payouts (
  id uuid primary key default gen_random_uuid(),
  courier_id uuid not null references auth.users(id) on delete cascade,
  amount integer not null check (amount > 0),
  destination text not null,
  status text not null default 'pending' check (status in ('pending','paid','rejected')),
  created_at timestamptz not null default now(),
  processed_at timestamptz
);
create index if not exists courier_payouts_courier_idx on public.courier_payouts(courier_id, created_at desc);
alter table public.courier_payouts enable row level security;
drop policy if exists courier_payouts_select_own on public.courier_payouts;
create policy courier_payouts_select_own on public.courier_payouts for select to authenticated using (courier_id=auth.uid() or exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
drop policy if exists courier_payouts_insert_own on public.courier_payouts;
create policy courier_payouts_insert_own on public.courier_payouts for insert to authenticated with check (courier_id=auth.uid());
create or replace function public.request_courier_payout(p_amount integer,p_destination text)
returns public.courier_payouts
language plpgsql security definer set search_path=public as $$
declare r public.courier_payouts; available integer;
begin
 if p_amount<=0 or nullif(trim(p_destination),'') is null then raise exception 'BAD_PAYOUT_REQUEST'; end if;
 select coalesce(sum(round((o.price::numeric)*0.80)),0)::integer into available
 from public.orders o where o.courier_id=auth.uid() and o.status='delivered';
 if p_amount>available then raise exception 'INSUFFICIENT_BALANCE'; end if;
 insert into public.courier_payouts(courier_id,amount,destination) values(auth.uid(),p_amount,trim(p_destination)) returning * into r;
 return r;
end; $$;
revoke all on function public.request_courier_payout(integer,text) from public;
grant execute on function public.request_courier_payout(integer,text) to authenticated;
