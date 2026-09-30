BMT GO v22 — PAYMENT FOUNDATION

Added:
- payment_method: cash or card
- payment_status: pending/paid/failed/refunded
- paid_at, payment_provider, payment_transaction_id
- client payment selection during order creation
- client/courier/admin payment status display
- courier can mark cash as received after delivery
- Supabase RPC mark_order_paid with authorization checks

IMPORTANT:
Card payment is only the app/UI foundation. No real money is charged until a Kazakhstan-compatible payment gateway is connected and its secure server/webhook is implemented. Never put secret merchant/API keys in the Flutter app.

Apply supabase/v22_payments.sql after the previous migrations.
Build with the same Supabase/Google Maps/Firebase configuration as v21.
