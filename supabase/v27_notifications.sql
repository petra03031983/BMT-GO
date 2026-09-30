-- BMT GO v27: in-app notifications + realtime events for clients, couriers and admins.
create extension if not exists pgcrypto;

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  type text not null default 'system',
  order_id uuid references public.orders(id) on delete cascade,
  payout_id uuid references public.courier_payouts(id) on delete cascade,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists notifications_user_created_idx on public.notifications(user_id, created_at desc);
create index if not exists notifications_unread_idx on public.notifications(user_id, read_at);
alter table public.notifications enable row level security;
drop policy if exists notifications_select_own on public.notifications;
create policy notifications_select_own on public.notifications for select to authenticated using(user_id=auth.uid());
drop policy if exists notifications_update_own on public.notifications;
create policy notifications_update_own on public.notifications for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());

alter table public.notifications replica identity full;

create or replace function public.bmt_notify_order_event()
returns trigger language plpgsql security definer set search_path=public as $$
declare
  cp record;
  title_text text;
  body_text text;
begin
  if tg_op='INSERT' then
    insert into public.notifications(user_id,title,body,type,order_id)
    values(new.client_id,'Заказ создан','BMT GO получил ваш заказ и ищет курьера.','order_created',new.id);

    -- Notify currently approved couriers that a new order is available.
    for cp in select id from public.courier_profiles where status='approved' loop
      insert into public.notifications(user_id,title,body,type,order_id)
      values(cp.id,'Новый заказ','Появился новый заказ BMT GO. Откройте приложение, чтобы принять его.','new_order',new.id);
    end loop;
    return new;
  end if;

  if tg_op='UPDATE' then
    if new.courier_id is distinct from old.courier_id and new.courier_id is not null then
      insert into public.notifications(user_id,title,body,type,order_id)
      values(new.courier_id,'Заказ назначен','Вам назначен заказ BMT GO.','order_assigned',new.id);
      insert into public.notifications(user_id,title,body,type,order_id)
      values(new.client_id,'Курьер найден','К заказу назначен курьер.','courier_assigned',new.id);
    end if;

    if new.status is distinct from old.status then
      title_text := case new.status
        when 'picked' then 'Заказ забран'
        when 'delivering' then 'Курьер в пути'
        when 'delivered' then 'Заказ доставлен'
        when 'searching' then 'Ищем курьера'
        else 'Статус заказа изменён' end;
      body_text := case new.status
        when 'picked' then 'Курьер забрал отправление.'
        when 'delivering' then 'Курьер направляется к получателю.'
        when 'delivered' then 'Доставка завершена.'
        when 'searching' then 'Ищем ближайшего курьера.'
        else 'Откройте заказ, чтобы посмотреть подробности.' end;
      insert into public.notifications(user_id,title,body,type,order_id)
      values(new.client_id,title_text,body_text,'order_status',new.id);
      if new.courier_id is not null then
        insert into public.notifications(user_id,title,body,type,order_id)
        values(new.courier_id,title_text,body_text,'order_status',new.id);
      end if;
    end if;
  end if;
  return new;
end; $$;

drop trigger if exists bmt_notify_order_event on public.orders;
create trigger bmt_notify_order_event after insert or update of courier_id,status on public.orders
for each row execute function public.bmt_notify_order_event();

create or replace function public.bmt_notify_payout_event()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if tg_op='INSERT' then
    insert into public.notifications(user_id,title,body,type,payout_id)
    values(new.courier_id,'Заявка на выплату принята',format('Заявка на %s ₸ отправлена администратору.',new.amount),'payout_created',new.id);
  elsif tg_op='UPDATE' and new.status is distinct from old.status then
    insert into public.notifications(user_id,title,body,type,payout_id)
    values(new.courier_id,
      case when new.status='paid' then 'Выплата выполнена' else 'Выплата отклонена' end,
      case when new.status='paid' then format('%s ₸ отмечены как выплаченные.',new.amount) else coalesce(new.rejection_reason,'Заявка отклонена администратором.') end,
      'payout_status',new.id);
  end if;
  return new;
end; $$;

drop trigger if exists bmt_notify_payout_event on public.courier_payouts;
create trigger bmt_notify_payout_event after insert or update of status on public.courier_payouts
for each row execute function public.bmt_notify_payout_event();

-- Enable realtime delivery for the app notification feed.
do $$ begin
  alter publication supabase_realtime add table public.notifications;
exception when duplicate_object then null;
end $$;

-- Keep the feed bounded in a simple MVP deployment.
create or replace function public.cleanup_old_notifications()
returns void language sql security definer set search_path=public as $$
  delete from public.notifications where created_at < now() - interval '90 days';
$$;
revoke all on function public.cleanup_old_notifications() from public;
