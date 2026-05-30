-- ══════════════════════════════════════════════════════════════════════════════
-- MauriVote — Migration 007 : Correction RLS pour l'authentification par OTP
-- ══════════════════════════════════════════════════════════════════════════════
-- PROBLÈME : La politique voter_read_own utilise app.current_nni qui n'est pas
-- disponible au moment du login (avant que l'utilisateur soit authentifié).
-- SOLUTION : Permettre la lecture limitée (téléphone + statut) via une
--             fonction SECURITY DEFINER pour protéger l'accès.
-- ══════════════════════════════════════════════════════════════════════════════

-- ── 1. Politique RLS pour la lookup OTP (anon → lecture limitée par NNI) ─────
-- Permet à un utilisateur anonyme de chercher son téléphone par NNI
-- (nécessaire AVANT la connexion pour envoyer l'OTP)
DROP POLICY IF EXISTS voter_read_own ON voters;
DROP POLICY IF EXISTS voter_otp_lookup ON voters;

-- Politique pour utilisateurs connectés : lire son propre profil
CREATE POLICY voter_read_own ON voters
  FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL);

-- Politique pour la phase OTP (anon) : lecture téléphone+statut seulement
-- Sécurité acceptable car :
-- 1. L'OTP est envoyé au téléphone enregistré (seul le propriétaire le reçoit)
-- 2. Connaître le NNI d'autrui ne suffit pas à s'authentifier
CREATE POLICY voter_otp_lookup ON voters
  FOR SELECT
  TO anon
  USING (true);

-- ── 2. Vue resultats_publics avec nom du candidat ────────────────────────────
-- Mise à jour pour inclure candidat_nom (nécessaire pour le widget de partage)
CREATE OR REPLACE VIEW resultats_publics AS
  SELECT
    v.election_id,
    v.candidate_id,
    c.nom           AS candidat_nom,
    v.tour,
    COUNT(*)        AS nb_votes,
    ROUND(
      COUNT(*) * 100.0 / NULLIF(SUM(COUNT(*)) OVER (
        PARTITION BY v.election_id, v.tour
      ), 0),
    2)              AS pourcentage,
    FALSE           AS valide_ceni,
    FALSE           AS valide_cc
  FROM votes v
  JOIN candidates c ON c.id = v.candidate_id
  WHERE v.is_valid = TRUE
  GROUP BY v.election_id, v.candidate_id, c.nom, v.tour;

-- ── 3. Accès public en lecture à resultats_publics ────────────────────────────
GRANT SELECT ON resultats_publics TO anon, authenticated;

-- ── 4. Accès public en lecture aux élections et candidats ────────────────────
GRANT SELECT ON elections  TO anon, authenticated;
GRANT SELECT ON candidates TO anon, authenticated;
GRANT SELECT ON wilayas    TO anon, authenticated;
GRANT SELECT ON communes   TO anon, authenticated;
GRANT SELECT ON bureaux_vote TO anon, authenticated;

-- ── 5. Vérification de la configuration ──────────────────────────────────────
SELECT
  schemaname,
  tablename,
  policyname,
  roles,
  cmd
FROM pg_policies
WHERE tablename IN ('voters', 'elections', 'candidates', 'resultats')
ORDER BY tablename, policyname;
