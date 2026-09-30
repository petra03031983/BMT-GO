-- BMT GO v18: automatic nearest courier assignment
-- Run after v16/v17 SQL.

alter table public.orders add column if not exists pickup_lat double precision;
alter table public.orders add column if not exists pickup_lng double precision;
alter table public.orders add column if not exists courier_id uuid references auth.users(id);
create index if not exists courier_locations_lat_lng_idx on public.courier_locations(lat,lng);
create index if not exists orders_courier_id_idx on public.orders(courier_id);

create or replace function public.assign_nearest_courier(
  p_order_id uuid,
  p_max_distance_km double precision default 15
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.orders;
  v_courier uuid;
begin
  select * into v_order from public.orders where id=p_order_id for update;
  if v_order.id is null then raise exception 'order_not_found'; end if;
  if v_order.status <> 'searching' then return v_order.courier_id; end if;
  if v_order.pickup_lat is null or v_order.pickup_lng is null then return null; end if;

  select cl.courier_id into v_courier
  from public.courier_locations cl
  join public.courier_profiles cp on cp.id=cl.courier_id
  where cp.status='approved'
    and cl.updated_at > now() - interval '2 minutes'
    and cl.courier_id <> coalesce(v_order.client_id, '00000000-0000-0000-0000-000000000000')
    and 6371 * 2 * asin(sqrt(
      power(sin(radians(cl.lat-v_order.pickup_lat)/2),2) +
      cos(radians(v_order.pickup_lat))*cos(radians(cl.lat))*power(sin(radians(cl.lng-v_order.pickup_lng)/2),2)
    )) <= p_max_distance_km
  order by 6371 * 2 * asin(sqrt(
      power(sin(radians(cl.lat-v_order.pickup_lat)/2),2) +
      cos(radians(v_order.pickup_lat))*cos(radians(cl.lat))*power(sin(radians(cl.lng-v_order.pickup_lng)/2),2)
    )) asc
  limit 1;

  if v_courier is null then return null; end if;

  update public.orders
  set courier_id=v_courier, status='assigned', updated_at=now()
  where id=p_order_id and status='searching';

  return v_courier;
end;
$$;

revoke all on function public.assign_nearest_courier(uuid,double precision) from public;
grant execute on function public.assign_nearest_courier(uuid,double precision) to authenticated;
