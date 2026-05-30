// ══════════════════════════════════════════════════════════════════════════════
// MauriVote — Edge Function : Envoi SMS OTP via Africa's Talking
// Gratuit en sandbox · Réel en production (+222 Mauritanie supporté)
// ══════════════════════════════════════════════════════════════════════════════
// Configuration Supabase Auth Hook :
//   Dashboard → Auth → Hooks → "Send SMS" → cette Edge Function
// ══════════════════════════════════════════════════════════════════════════════

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';

// ── Variables d'environnement ─────────────────────────────────────────────────
const AT_USERNAME = Deno.env.get('AT_USERNAME') ?? 'sandbox';   // 'sandbox' = gratuit
const AT_API_KEY  = Deno.env.get('AT_API_KEY')  ?? '';
const AT_SENDER   = Deno.env.get('AT_SENDER')   ?? 'MauriVote'; // Identifiant expéditeur

// En sandbox : endpoint de test (pas de vrai SMS, visible dans le dashboard AT)
// En production : endpoint réel (vrai SMS envoyé sur le téléphone)
const AT_ENDPOINT = AT_USERNAME === 'sandbox'
  ? 'https://api.sandbox.africastalking.com/version1/messaging'
  : 'https://api.africastalking.com/version1/messaging';

// ── Handler principal ─────────────────────────────────────────────────────────
serve(async (req: Request) => {
  // Supabase appelle ce hook avec POST JSON :
  // { "user": { "phone": "+22220000001", ... }, "otp": "123456" }
  let phone: string;
  let otp: string;

  try {
    const body = await req.json();
    // Support des deux formats : hook Supabase Auth ou appel direct
    phone = body?.user?.phone ?? body?.phone ?? '';
    otp   = body?.otp ?? '';
  } catch {
    return new Response(JSON.stringify({ error: 'Corps JSON invalide' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  if (!phone || !otp) {
    return new Response(JSON.stringify({ error: 'phone et otp requis' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  // ── Normaliser le numéro mauritanien ────────────────────────────────────────
  // Africa's Talking accepte le format international : +22220000001
  const phoneNormalized = phone.startsWith('+') ? phone : `+${phone}`;

  // ── Message OTP ─────────────────────────────────────────────────────────────
  const message = `Votre code MauriVote : ${otp}\nValable 2 minutes. Ne partagez ce code avec personne.`;

  // ── Appel API Africa's Talking ───────────────────────────────────────────────
  const formData = new URLSearchParams();
  formData.append('username', AT_USERNAME);
  formData.append('to',       phoneNormalized);
  formData.append('message',  message);
  if (AT_USERNAME !== 'sandbox') {
    // En production : identifiant expéditeur personnalisé (optionnel selon le pays)
    formData.append('from', AT_SENDER);
  }

  try {
    const resp = await fetch(AT_ENDPOINT, {
      method: 'POST',
      headers: {
        'apiKey':       AT_API_KEY,
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept':       'application/json',
      },
      body: formData.toString(),
    });

    const result = await resp.json();

    // Africa's Talking retourne SMSMessageData avec Recipients[]
    const recipients = result?.SMSMessageData?.Recipients ?? [];
    const success    = recipients.some(
      (r: { status: string }) => r.status === 'Success',
    );

    console.log(`SMS OTP → ${phoneNormalized} | mode: ${AT_USERNAME} | ok: ${success}`);
    console.log(JSON.stringify(result));

    // Supabase attend une réponse 200 avec {} pour considérer le hook réussi
    return new Response(JSON.stringify({ success, result }), {
      status: success ? 200 : 500,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('Erreur Africa\'s Talking:', err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
