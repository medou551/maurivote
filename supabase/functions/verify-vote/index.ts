// supabase/functions/verify-vote/index.ts
// Edge Function — Vérification anonyme d'un reçu de vote (QR Code)

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { persistSession: false } }
    );

    // ── Parser le reçu hash ───────────────────────────────────────────────
    const { recu_hash } = await req.json();

    if (!recu_hash || typeof recu_hash !== "string" ||
        recu_hash.length !== 64) {
      return new Response(
        JSON.stringify({ error: "recu_hash invalide" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // ── Vérifier l'existence du hash dans la BDD ──────────────────────────
    // On vérifie SEULEMENT si le reçu existe — on ne révèle PAS le candidat
    const { data, error } = await supabase
      .from("votes")
      .select("id, timestamp_vote, election_id, tour")  // PAS candidate_id !
      .eq("recu_hash", recu_hash)
      .eq("is_valid", true)
      .maybeSingle();

    if (error) {
      console.error("DB error:", error);
      return new Response(
        JSON.stringify({ error: "Erreur serveur" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!data) {
      return new Response(
        JSON.stringify({
          exists: false,
          message: "Ce reçu ne correspond à aucun vote enregistré"
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // ── Retourner la confirmation (sans révéler le candidat) ─────────────
    return new Response(
      JSON.stringify({
        exists: true,
        timestamp: data.timestamp_vote,
        election_id: data.election_id,
        tour: data.tour,
        message: "Votre vote a bien été enregistré et comptabilisé",
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );

  } catch (error) {
    console.error("Unexpected error:", error);
    return new Response(
      JSON.stringify({ error: "Erreur serveur inattendue" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
