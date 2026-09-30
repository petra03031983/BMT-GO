-- BMT GO v20: road-route metadata
alter table public.orders add column if not exists route_distance_km double precision;
alter table public.orders add column if not exists route_duration_min integer;
create index if not exists orders_route_distance_idx on public.orders(route_distance_km);
