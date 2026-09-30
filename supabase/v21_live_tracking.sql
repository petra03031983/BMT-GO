-- BMT GO v21: live courier tracking for an assigned order
create index if not exists courier_locations_courier_updated_idx
  on public.courier_locations(courier_id, updated_at desc);

-- Realtime is expected to be enabled for courier_locations in Supabase.
-- The mobile client subscribes only to the assigned courier_id.

alter table public.courier_locations enable row level security;

drop policy if exists "courier locations select authenticated" on public.courier_locations;
create policy "courier locations select authenticated"
on public.courier_locations for select to authenticated using (true);
