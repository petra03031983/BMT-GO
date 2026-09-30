-- BMT GO v28: profile/history support
-- profiles already has owner-only UPDATE policy from v15.
-- Add indexes to keep order history fast as the service grows.
create index if not exists orders_client_created_idx on public.orders(client_id, created_at desc);
create index if not exists orders_courier_created_idx on public.orders(courier_id, created_at desc);
create index if not exists orders_status_created_idx on public.orders(status, created_at desc);
