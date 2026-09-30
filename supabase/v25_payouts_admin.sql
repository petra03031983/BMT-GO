-- BMT GO v25: safe courier balance + admin payout processing
alter table public.courier_payouts add column if not exists rejection_reason text;
create index if not exists courier_payouts_status_idx on public.courier_payouts(status, created_at desc);

create or replace function public.request_courier_payout(p_amount integer,p_destination text)
returns public.courier_payouts
language plpgsql security definer set search_path=public as $$
declare r public.courier_payouts; earned integer; reserved integer;
begin
 if p_amount<=0 or nullif(trim(p_destination),'') is null then raise exception 'BAD_PAYOUT_REQUEST'; end if;
 select coalesce(sum(round((o.price::numeric)*0.80)),0)::integer into earned
 from public.orders o where o.courier_id=auth.uid() and o.status='delivered';
 select coalesce(sum(amount),0)::integer into reserved
 from public.courier_payouts where courier_id=auth.uid() and status in ('pending','paid');
 if p_amount > greatest(earned-reserved,0) then raise exception 'INSUFFICIENT_BALANCE'; end if;
 insert into public.courier_payouts(courier_id,amount,destination) values(auth.uid(),p_amount,trim(p_destination)) returning * into r;
 return r;
end; $$;
revoke all on function public.request_courier_payout(integer,text) from public;
grant execute on function public.request_courier_payout(integer,text) to authenticated;

create or replace function public.admin_process_courier_payout(p_payout_id uuid,p_action text,p_reason text default null)
returns public.courier_payouts
language plpgsql security definer set search_path=public as $$
declare r public.courier_payouts;
begin
 if not exists(select 1 from public.profiles where id=auth.uid() and role='admin') then raise exception 'ADMIN_ONLY'; end if;
 if p_action not in ('paid','rejected') then raise exception 'BAD_PAYOUT_ACTION'; end if;
 update public.courier_payouts
 set status=p_action,
     processed_at=now(),
     rejection_reason=case when p_action='rejected' then nullif(trim(coalesce(p_reason,'')),'') else null end
 where id=p_payout_id and status='pending'
 returning * into r;
 if r.id is null then raise exception 'PAYOUT_NOT_PENDING'; end if;
 return r;
end; $$;
revoke all on function public.admin_process_courier_payout(uuid,text,text) from public;
grant execute on function public.admin_process_courier_payout(uuid,text,text) to authenticated;
