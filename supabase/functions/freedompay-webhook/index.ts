import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const enc = new TextEncoder()
async function sha256Hex(input: string) {
  const hash = await crypto.subtle.digest('SHA-256', enc.encode(input))
  return [...new Uint8Array(hash)].map(b => b.toString(16).padStart(2, '0')).join('')
}

async function verify(script: string, params: Record<string,string>, secret: string) {
  const supplied = params.pg_sig
  if (!supplied) return false
  const copy = { ...params }; delete copy.pg_sig
  const fields = Object.keys(copy).sort().map(k => `${k}=${copy[k]}`)
  return (await sha256Hex(`${script};${fields.join(';')};${secret}`)) === supplied
}

Deno.serve(async (req) => {
  try {
    const body = await req.text()
    const params: Record<string,string> = {}
    if (req.headers.get('content-type')?.includes('application/json')) Object.assign(params, await (async()=>JSON.parse(body))())
    else new URLSearchParams(body).forEach((v,k)=>params[k]=v)
    const secret = Deno.env.get('FREEDOMPAY_SECRET_KEY')
    if (!secret || !(await verify('freedompay-webhook', params, secret))) return new Response('Invalid signature', { status: 403 })

    const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!)
    const orderId = params.pg_order_id
    const paymentId = params.pg_payment_id
    const status = params.pg_result === '1' || params.pg_status === 'ok' ? 'paid' : 'failed'
    if (!orderId) return new Response('Missing order', { status: 400 })
    await supabase.from('orders').update({ payment_status: status, payment_provider: 'freedompay', payment_transaction_id: paymentId ?? null, paid_at: status === 'paid' ? new Date().toISOString() : null }).eq('id', orderId)
    return new Response('OK', { status: 200 })
  } catch (e) { return new Response(String(e), { status: 500 }) }
})
