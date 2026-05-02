// supabase/functions/check-voted/index.ts
// Vérifie si un voter_hash a déjà voté pour une élection/tour donné
// Accessible uniquement avec JWT valide

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { persistSession: false } }
    );

    // Vérifier JWT
    const jwt = req.headers.get("Authorization")?.replace("Bearer ", "");
    if (!jwt) return json(401, { error: "Non authentifié" });

    const { data: { user }, error: authErr } = await supabase.auth.getUser(jwt);
    if (authErr || !user) return json(401, { error: "Session invalide" });

    const { voter_hash, election_id, tour = 1 } = await req.json();

    if (!voter_hash || !election_id) {
      return json(400, { error: "voter_hash et election_id requis" });
    }

    // Chercher un vote existant pour ce voter_hash
    const { data, error } = await supabase
      .from("votes")
      .select("id, timestamp_vote")
      .eq("voter_hash", voter_hash)
      .eq("election_id", election_id)
      .eq("tour", tour)
      .eq("is_valid", true)
      .maybeSingle();

    if (error) return json(500, { error: "Erreur BDD" });

    return json(200, {
      has_voted: data !== null,
      voted_at: data?.timestamp_vote ?? null,
    });

  } catch (e) {
    console.error(e);
    return json(500, { error: "Erreur serveur" });
  }
});

function json(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}
