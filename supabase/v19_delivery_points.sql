-- BMT GO v19: delivery points, distance and estimated price
alter table public.orders add column if not exists dropoff_lat double precision;
alter table public.orders add column if not exists dropoff_lng double precision;
alter table public.orders add column if not exists distance_km double precision;
create index if not exists orders_dropoff_idx on public.orders(dropoff_lat, dropoff_lng);

-- Optional helper for server-side price estimation.
create or replace function public.estimate_delivery_price(p_distance_km double precision)
returns integer language sql immutable as $$
  select greatest(1500, 1500 + ceil(greatest(coalesce(p_distance_km,0),0))::integer * 300);
$$;
revoke all on function public.estimate_delivery_price(double precision) from public;
grant execute on function public.estimate_delivery_price(double precision) to authenticated;
