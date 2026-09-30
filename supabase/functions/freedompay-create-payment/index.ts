import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const enc = new TextEncoder()
async function sha256Hex(input: string) {
  const hash = await crypto.subtle.digest('SHA-256', enc.encode(input))
  return [...new Uint8Array(hash)].map(b => b.toString(16).padStart(2, '0')).join('')
}

function signature(script: string, params: Record<string, string>, secret: string) {
  const fields = Object.keys(params).sort().map(k => `${k}=${params[k]}`)
  return sha256Hex(`${script};${fields.join(';')};${secret}`)
}

Deno.serve(async (req) => {
  try {
    const auth = req.headers.get('Authorization')
    if (!auth) return new Response('Unauthorized', { status: 401 })
    const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, { global: { headers: { Authorization: auth } } })
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return new Response('Unauthorized', { status: 401 })

    const { order_id } = await req.json()
    const { data: order, error } = await supabase.from('orders').select('id,client_id,price,payment_method,payment_status').eq('id', order_id).single()
    if (error || !order || order.client_id !== user.id) return new Response('Order not found', { status: 404 })
    if (order.payment_method !== 'card') return new Response('Card payment is not selected', { status: 400 })
    if (order.payment_status === 'paid') return Response.json({ paid: true })

    const merchant = Deno.env.get('FREEDOMPAY_MERCHANT_ID')
    const secret = Deno.env.get('FREEDOMPAY_SECRET_KEY')
    const baseUrl = Deno.env.get('BMT_GO_PUBLIC_URL')
    if (!merchant || !secret || !baseUrl) return new Response('Payment gateway is not configured', { status: 503 })

    const salt = crypto.randomUUID().replaceAll('-', '')
    const params: Record<string, string> = {
      pg_merchant_id: merchant,
      pg_amount: Number(order.price).toFixed(2),
      pg_order_id: String(order.id),
      pg_description: `BMT GO order ${order.id}`,
      pg_salt: salt,
      pg_currency: 'KZT',
      pg_success_url: `${baseUrl}/payment/success`,
      pg_failure_url: `${baseUrl}/payment/failure`,
      pg_result_url: `${Deno.env.get('SUPABASE_URL')}/functions/v1/freedompay-webhook`,
    }
    params.pg_sig = await signature('init_payment.php', params, secret)

    const form = new URLSearchParams(params)
    const response = await fetch('https://api.freedompay.kz/init_payment.php', { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: form })
    const xml = await response.text()
    const redirect = xml.match(/<pg_redirect_url>([^<]+)<\/pg_redirect_url>/)?.[1]
    const paymentId = xml.match(/<pg_payment_id>([^<]+)<\/pg_payment_id>/)?.[1]
    if (!redirect || !paymentId) return new Response(`Gateway error: ${xml.slice(0, 1000)}`, { status: 502 })

    await supabase.from('orders').update({ payment_provider: 'freedompay', payment_transaction_id: paymentId, payment_checkout_url: redirect, payment_created_at: new Date().toISOString() }).eq('id', order.id)
    return Response.json({ redirect_url: redirect, payment_id: paymentId })
  } catch (e) {
    return new Response(String(e), { status: 500 })
  }
})
