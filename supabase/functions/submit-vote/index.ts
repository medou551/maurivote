// supabase/functions/submit-vote/index.ts
// Edge Function Supabase — Soumission sécurisée d'un vote
// Runtime : Deno 1.x | Timeout : 30s | Auth : JWT obligatoire

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { hmac } from "https://deno.land/x/hmac@v2.0.1/mod.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface VotePayload {
  voter_hash:   string;
  election_id:  string;
  candidate_id: string;
  tour:         number;
  vote_chiffre: string;
  iv:           string;
  signature:    string;
  recu_hash:    string;
}

serve(async (req: Request) => {
  // ── CORS preflight ─────────────────────────────────────────────────────────
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ── 1. Initialiser le client Supabase avec les droits admin ──────────────
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { persistSession: false } }
    );

    // ── 2. Vérifier l'authentification JWT ────────────────────────────────────
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return errorResponse(401, "Non authentifié");
    }

    const jwt = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(jwt);

    if (authError || !user) {
      return errorResponse(401, "Session invalide ou expirée");
    }

    // ── 3. Parser et valider le payload ───────────────────────────────────────
    const body: VotePayload = await req.json();

    if (!isValidPayload(body)) {
      return errorResponse(400, "Payload invalide — champs manquants ou format incorrect");
    }

    // ── 4. Vérifier la signature HMAC du payload ──────────────────────────────
    const selServeur = Deno.env.get("VOTE_ENCRYPTION_SEL") ?? "";
    const signatureInput = body.vote_chiffre + body.iv;
    const expectedSig = await hmacSign(signatureInput, selServeur);

    if (!timingSafeEqual(expectedSig, body.signature)) {
      await logAudit(supabaseAdmin, {
        action_type: "vote_fail",
        actor_hash: body.voter_hash,
        election_id: body.election_id,
        success: false,
        detail: { reason: "invalid_signature" },
      });
      return errorResponse(400, "Signature invalide");
    }

    // ── 5. Vérifier que l'élection est en cours ───────────────────────────────
    const { data: election, error: elecError } = await supabaseAdmin
      .from("elections")
      .select("statut, date_ouverture, date_fermeture, tour_actuel")
      .eq("id", body.election_id)
      .single();

    if (elecError || !election) {
      return errorResponse(404, "Élection introuvable");
    }

    const now = new Date();
    const ouverture = new Date(election.date_ouverture);
    const fermeture = new Date(election.date_fermeture);

    if (election.statut !== "en_cours" || now < ouverture || now > fermeture) {
      return errorResponse(403, "Le vote n'est pas ouvert pour cette élection");
    }

    if (election.tour_actuel !== body.tour) {
      return errorResponse(400, `Le tour actuel est ${election.tour_actuel}`);
    }

    // ── 6. Vérifier que le candidat appartient à cette élection ───────────────
    const { data: candidate } = await supabaseAdmin
      .from("candidates")
      .select("id, tour, is_active")
      .eq("id", body.candidate_id)
      .eq("election_id", body.election_id)
      .eq("tour", body.tour)
      .eq("is_active", true)
      .single();

    if (!candidate) {
      return errorResponse(400, "Candidat invalide pour cette élection/tour");
    }

    // ── 7. Insérer le vote (la contrainte UNIQUE bloque le double vote) ───────
    const ipHash = await sha256Hash(
      req.headers.get("x-forwarded-for") ?? "unknown"
    );
    const deviceHash = await sha256Hash(
      req.headers.get("user-agent") ?? "unknown"
    );

    const { error: insertError } = await supabaseAdmin
      .from("votes")
      .insert({
        voter_hash:   body.voter_hash,
        election_id:  body.election_id,
        candidate_id: body.candidate_id,
        tour:         body.tour,
        vote_chiffre: body.vote_chiffre,
        iv:           body.iv,
        signature:    body.signature,
        recu_hash:    body.recu_hash,
        ip_hash:      ipHash,
        device_hash:  deviceHash,
      });

    // ── 8. Gérer le double vote ───────────────────────────────────────────────
    if (insertError) {
      if (insertError.code === "23505") {  // Violation de contrainte UNIQUE
        return errorResponse(409, "Vous avez déjà voté pour cette élection");
      }
      console.error("Insert error:", insertError);
      return errorResponse(500, "Erreur lors de l'enregistrement du vote");
    }

    // ── 9. Retourner le reçu de confirmation ─────────────────────────────────
    return new Response(
      JSON.stringify({
        success:       true,
        recu_hash:     body.recu_hash,
        timestamp:     now.toISOString(),
        election_id:   body.election_id,
        tour:          body.tour,
        message:       "Votre vote a été enregistré avec succès",
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );

  } catch (error) {
    console.error("Unexpected error:", error);
    return errorResponse(500, "Erreur serveur inattendue");
  }
});

// ── Helpers ───────────────────────────────────────────────────────────────────

function isValidPayload(body: unknown): body is VotePayload {
  const b = body as Record<string, unknown>;
  return (
    typeof b.voter_hash   === "string" && b.voter_hash.length === 64 &&
    typeof b.election_id  === "string" && isValidUuid(b.election_id) &&
    typeof b.candidate_id === "string" && isValidUuid(b.candidate_id) &&
    typeof b.tour         === "number" && [1, 2].includes(b.tour) &&
    typeof b.vote_chiffre === "string" && b.vote_chiffre.length > 0 &&
    typeof b.iv           === "string" && b.iv.length > 0 &&
    typeof b.signature    === "string" && b.signature.length === 64 &&
    typeof b.recu_hash    === "string" && b.recu_hash.length === 64
  );
}

function isValidUuid(value: unknown): boolean {
  return typeof value === "string" &&
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
}

async function hmacSign(data: string, key: string): Promise<string> {
  const enc = new TextEncoder();
  const cryptoKey = await crypto.subtle.importKey(
    "raw", enc.encode(key), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]
  );
  const sig = await crypto.subtle.sign("HMAC", cryptoKey, enc.encode(data));
  return Array.from(new Uint8Array(sig))
    .map(b => b.toString(16).padStart(2, "0"))
    .join("");
}

async function sha256Hash(data: string): Promise<string> {
  const enc = new TextEncoder();
  const hashBuffer = await crypto.subtle.digest("SHA-256", enc.encode(data));
  return Array.from(new Uint8Array(hashBuffer))
    .map(b => b.toString(16).padStart(2, "0"))
    .join("");
}

// Comparaison en temps constant (anti-timing attack)
function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}

function errorResponse(status: number, message: string): Response {
  return new Response(
    JSON.stringify({ success: false, error: message }),
    { status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
  );
}

// deno-lint-ignore no-explicit-any
async function logAudit(client: any, data: Record<string, unknown>) {
  try {
    await client.from("audit_logs").insert(data);
  } catch (e) {
    console.error("Audit log failed:", e);
  }
}
