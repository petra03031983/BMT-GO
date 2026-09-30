-- BMT GO v22: payment method and payment status
alter table public.orders
  add column if not exists payment_method text not null default 'cash',
  add column if not exists payment_status text not null default 'pending',
  add column if not exists paid_at timestamptz,
  add column if not exists payment_provider text,
  add column if not exists payment_transaction_id text;

alter table public.orders
  drop constraint if exists orders_payment_method_check;
alter table public.orders
  add constraint orders_payment_method_check
  check (payment_method in ('cash','card'));

alter table public.orders
  drop constraint if exists orders_payment_status_check;
alter table public.orders
  add constraint orders_payment_status_check
  check (payment_status in ('pending','paid','failed','refunded'));

create index if not exists orders_payment_status_idx
  on public.orders(payment_status);

create or replace function public.mark_order_paid(
  p_order_id uuid,
  p_payment_method text
)
returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.orders;
begin
  select * into v_order from public.orders where id = p_order_id for update;
  if not found then raise exception 'ORDER_NOT_FOUND'; end if;
  if v_order.client_id <> auth.uid()
     and v_order.courier_id <> auth.uid()
     and not exists (select 1 from public.profiles p where p.id=auth.uid() and p.role='admin') then
    raise exception 'NOT_ALLOWED';
  end if;
  if p_payment_method <> v_order.payment_method then
    raise exception 'PAYMENT_METHOD_MISMATCH';
  end if;
  update public.orders
    set payment_status='paid', paid_at=now(), payment_provider=case when p_payment_method='cash' then 'cash' else payment_provider end
    where id=p_order_id
    returning * into v_order;
  return v_order;
end;
$$;

revoke all on function public.mark_order_paid(uuid,text) from public;
grant execute on function public.mark_order_paid(uuid,text) to authenticated;

-- For card payments, do NOT mark the order paid from the mobile app in production.
-- A trusted payment webhook/server function should set payment_status='paid' and
-- store payment_provider/payment_transaction_id after the gateway confirms payment.
