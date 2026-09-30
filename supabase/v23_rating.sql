-- BMT GO v23: courier ratings and order history support
create table if not exists public.order_ratings (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders(id) on delete cascade,
  client_id uuid not null references auth.users(id) on delete cascade,
  courier_id uuid not null references auth.users(id) on delete cascade,
  rating smallint not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now()
);

create index if not exists order_ratings_courier_idx on public.order_ratings(courier_id);
create index if not exists order_ratings_client_idx on public.order_ratings(client_id);

alter table public.order_ratings enable row level security;

drop policy if exists order_ratings_select_own on public.order_ratings;
create policy order_ratings_select_own on public.order_ratings
for select to authenticated using (client_id = auth.uid() or courier_id = auth.uid() or exists (select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));

drop policy if exists order_ratings_insert_client on public.order_ratings;
create policy order_ratings_insert_client on public.order_ratings
for insert to authenticated with check (client_id = auth.uid());

create or replace function public.submit_order_rating(
  p_order_id uuid,
  p_rating smallint,
  p_comment text default null
)
returns public.order_ratings
language plpgsql
security definer
set search_path = public
as $$
declare
  o public.orders;
  r public.order_ratings;
begin
  select * into o from public.orders where id=p_order_id;
  if not found then raise exception 'ORDER_NOT_FOUND'; end if;
  if o.client_id <> auth.uid() then raise exception 'NOT_ALLOWED'; end if;
  if o.status <> 'delivered' then raise exception 'ORDER_NOT_DELIVERED'; end if;
  if o.courier_id is null then raise exception 'NO_COURIER'; end if;
  if p_rating < 1 or p_rating > 5 then raise exception 'BAD_RATING'; end if;
  if exists(select 1 from public.order_ratings where order_id=p_order_id) then raise exception 'ALREADY_RATED'; end if;

  insert into public.order_ratings(order_id,client_id,courier_id,rating,comment)
  values(p_order_id,o.client_id,o.courier_id,p_rating,nullif(trim(p_comment),''))
  returning * into r;
  return r;
end;
$$;

revoke all on function public.submit_order_rating(uuid,smallint,text) from public;
grant execute on function public.submit_order_rating(uuid,smallint,text) to authenticated;

-- Add rating to courier profile for quick display.
alter table public.courier_profiles
  add column if not exists rating_avg numeric(3,2) not null default 0,
  add column if not exists rating_count integer not null default 0;

create or replace function public.refresh_courier_rating()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.courier_profiles c
  set rating_avg = coalesce((select round(avg(rating)::numeric,2) from public.order_ratings r where r.courier_id=c.id),0),
      rating_count = (select count(*) from public.order_ratings r where r.courier_id=c.id)
  where c.id = new.courier_id;
  return new;
end;
$$;

drop trigger if exists trg_refresh_courier_rating on public.order_ratings;
create trigger trg_refresh_courier_rating
after insert on public.order_ratings
for each row execute function public.refresh_courier_rating();

-- Helpful view for courier history/rating.
create or replace view public.courier_order_history as
select o.id,o.code,o.client_id,o.courier_id,o.status,o.price,o.created_at,o.updated_at,
       r.rating,r.comment as rating_comment,r.created_at as rated_at
from public.orders o
left join public.order_ratings r on r.order_id=o.id
where o.courier_id is not null;
