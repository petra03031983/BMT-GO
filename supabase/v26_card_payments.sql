-- BMT GO v26: card payment session support for Freedom Pay
alter table public.orders
  add column if not exists payment_checkout_url text,
  add column if not exists payment_created_at timestamptz;

create index if not exists orders_payment_tx_idx on public.orders(payment_transaction_id);

-- Only the trusted Edge Function should update card payment fields in production.
-- The mobile app must never mark a card order as paid.
