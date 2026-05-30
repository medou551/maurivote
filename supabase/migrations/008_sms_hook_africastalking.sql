-- ══════════════════════════════════════════════════════════════════════════════
-- MauriVote — Migration 008 : Hook SMS via Africa's Talking
-- ══════════════════════════════════════════════════════════════════════════════
-- Ce hook est appelé par Supabase Auth chaque fois qu'un OTP doit être envoyé.
-- Il transmet l'OTP à notre Edge Function send-sms-otp qui contacte
-- Africa's Talking (sandbox gratuit → production réelle +222 Mauritanie).
--
-- INSTRUCTIONS SUPABASE CLOUD :
--   1. Déployer l'Edge Function :
--      supabase functions deploy send-sms-otp --project-ref VOTRE_REF
--   2. Ajouter les secrets :
--      supabase secrets set AT_USERNAME=sandbox AT_API_KEY=test --project-ref VOTRE_REF
--   3. Dans Dashboard → Auth → Hooks → "Send SMS" :
--      Sélectionner "Edge Function" → send-sms-otp
-- ══════════════════════════════════════════════════════════════════════════════

-- ── Extension pour requêtes HTTP depuis Postgres ──────────────────────────────
CREATE EXTENSION IF NOT EXISTS pg_net;

-- ── Fonction hook : appelée par Supabase Auth pour chaque OTP ─────────────────
-- Cette fonction est le "hook" côté Postgres. Elle appelle l'Edge Function
-- send-sms-otp via pg_net (HTTP asynchrone depuis la BD).
CREATE OR REPLACE FUNCTION public.send_sms_hook(event jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  phone text;
  otp   text;
BEGIN
  phone := event -> 'user' ->> 'phone';
  otp   := event ->> 'otp';

  PERFORM net.http_post(
    url     := 'https://nwdpxruiqhjrplvrfaks.supabase.co/functions/v1/send-sms-otp',
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im53ZHB4cnVpcWhqcnBsdnJmYWtzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NzY3NTU3NCwiZXhwIjoyMDkzMjUxNTc0fQ.W3-9GtVwf_qMKGGX5J4DQh9R9XYmVkF-li2oV2j9m1M'
    ),
    body    := jsonb_build_object(
      'user', jsonb_build_object('phone', phone),
      'otp',  otp
    )
  );

  RETURN '{}'::jsonb;
EXCEPTION WHEN others THEN
  RAISE LOG 'send_sms_hook erreur: %', SQLERRM;
  RETURN '{}'::jsonb;
END;
$$;

-- ── Droits d'exécution pour Supabase Auth ─────────────────────────────────────
GRANT EXECUTE ON FUNCTION public.send_sms_hook TO supabase_auth_admin;
REVOKE EXECUTE ON FUNCTION public.send_sms_hook FROM PUBLIC, anon, authenticated;

-- ── Vérification : la fonction existe ────────────────────────────────────────
SELECT
  routine_name,
  routine_type,
  security_type
FROM information_schema.routines
WHERE routine_name = 'send_sms_hook'
  AND routine_schema = 'public';
