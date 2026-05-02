-- ══════════════════════════════════════════════════════════════════════════════
-- MauriVote — Migration 004 : Optimisations Realtime + Index Sprint 3
-- ══════════════════════════════════════════════════════════════════════════════

-- ── 1. Activation Supabase Realtime sur resultats ─────────────────────────────
-- (À exécuter dans Supabase Dashboard → Database → Replication)
-- Activer pour la table resultats : INSERT, UPDATE, DELETE

-- Commande Supabase CLI équivalente :
-- supabase db execute "ALTER TABLE resultats REPLICA IDENTITY FULL;"
ALTER TABLE resultats REPLICA IDENTITY FULL;
ALTER TABLE votes     REPLICA IDENTITY FULL;

-- ── 2. Index performance pour les requêtes temps réel ─────────────────────────

-- Index pour les résultats par élection/tour (la requête la plus fréquente)
CREATE INDEX CONCURRENTLY IF NOT EXISTS
  idx_resultats_election_tour
  ON resultats (election_id, tour, nb_votes DESC);

-- Index pour les votes par élection/tour (pour les aggrégations)
CREATE INDEX CONCURRENTLY IF NOT EXISTS
  idx_votes_election_tour_valid
  ON votes (election_id, tour, is_valid)
  WHERE is_valid = TRUE;

-- Index pour la vérification du reçu QR (très fréquent lors des vérifications)
CREATE INDEX CONCURRENTLY IF NOT EXISTS
  idx_votes_recu_valid
  ON votes (recu_hash, is_valid)
  WHERE is_valid = TRUE;

-- Index pour la recherche par voter_hash (vérification double vote)
CREATE INDEX CONCURRENTLY IF NOT EXISTS
  idx_votes_voter_election_tour
  ON votes (voter_hash, election_id, tour)
  WHERE is_valid = TRUE;

-- Index pour les élections actives (accueil app)
CREATE INDEX CONCURRENTLY IF NOT EXISTS
  idx_elections_statut_public
  ON elections (statut, is_public, date_fermeture)
  WHERE is_public = TRUE AND statut != 'annulee';

-- Index pour les candidats actifs par élection
CREATE INDEX CONCURRENTLY IF NOT EXISTS
  idx_candidates_election_active
  ON candidates (election_id, tour, is_active)
  WHERE is_active = TRUE;

-- ── 3. Fonction de mise à jour automatique des résultats ──────────────────────
-- Appelée par trigger après chaque vote pour mettre à jour la table resultats

CREATE OR REPLACE FUNCTION update_resultats_after_vote()
RETURNS TRIGGER AS $$
DECLARE
  total_votes INTEGER;
BEGIN
  -- Calculer le total des votes pour cette élection/tour
  SELECT COUNT(*) INTO total_votes
  FROM votes
  WHERE election_id = NEW.election_id
    AND tour = NEW.tour
    AND is_valid = TRUE;

  -- Insérer ou mettre à jour le résultat du candidat
  INSERT INTO resultats (election_id, candidate_id, tour, nb_votes, pourcentage, updated_at)
  VALUES (
    NEW.election_id,
    NEW.candidate_id,
    NEW.tour,
    1,  -- sera recalculé ci-dessous
    0,  -- sera recalculé ci-dessous
    NOW()
  )
  ON CONFLICT (election_id, candidate_id, tour)
  DO UPDATE SET
    nb_votes   = (
      SELECT COUNT(*) FROM votes
      WHERE election_id = NEW.election_id
        AND candidate_id = candidates_tbl.candidate_id
        AND tour = NEW.tour
        AND is_valid = TRUE
    ),
    updated_at = NOW()
  FROM (SELECT NEW.candidate_id AS candidate_id) AS candidates_tbl;

  -- Recalculer les pourcentages pour tous les candidats de cette élection/tour
  UPDATE resultats r
  SET pourcentage = CASE
    WHEN total_votes > 0
    THEN ROUND((r.nb_votes::NUMERIC / total_votes * 100), 2)
    ELSE 0
  END
  WHERE r.election_id = NEW.election_id
    AND r.tour = NEW.tour;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Attacher le trigger sur votes
CREATE TRIGGER trg_update_resultats_on_vote
  AFTER INSERT ON votes
  FOR EACH ROW EXECUTE FUNCTION update_resultats_after_vote();

-- ── 4. Fonction broadcast Realtime après mise à jour des résultats ─────────────
CREATE OR REPLACE FUNCTION broadcast_resultat_update()
RETURNS TRIGGER AS $$
BEGIN
  -- Notifier les clients WebSocket via pg_notify
  PERFORM pg_notify(
    'resultats_update',
    json_build_object(
      'election_id', NEW.election_id,
      'candidate_id', NEW.candidate_id,
      'tour', NEW.tour,
      'nb_votes', NEW.nb_votes,
      'pourcentage', NEW.pourcentage,
      'timestamp', NOW()
    )::TEXT
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_broadcast_resultats
  AFTER INSERT OR UPDATE ON resultats
  FOR EACH ROW EXECUTE FUNCTION broadcast_resultat_update();

-- ── 5. Vue matérialisée pour les résultats avec infos candidats ───────────────
CREATE MATERIALIZED VIEW IF NOT EXISTS resultats_avec_candidats AS
  SELECT
    r.election_id,
    r.candidate_id,
    r.tour,
    r.nb_votes,
    r.pourcentage,
    r.valide_ceni,
    r.valide_cc,
    r.updated_at,
    c.nom           AS candidat_nom,
    c.parti         AS candidat_parti,
    c.parti_ar      AS candidat_parti_ar,
    c.numero_candidat,
    c.couleur_parti,
    c.photo_url,
    RANK() OVER (
      PARTITION BY r.election_id, r.tour
      ORDER BY r.nb_votes DESC
    ) AS rang
  FROM resultats r
  JOIN candidates c ON c.id = r.candidate_id
  WHERE c.is_active = TRUE;

CREATE UNIQUE INDEX ON resultats_avec_candidats (election_id, candidate_id, tour);

-- Rafraîchir la vue matérialisée toutes les 5 minutes (via pg_cron si disponible)
-- SELECT cron.schedule('refresh-resultats', '*/5 * * * *',
--   'REFRESH MATERIALIZED VIEW CONCURRENTLY resultats_avec_candidats');

-- ── 6. Statistiques de participation par wilaya ────────────────────────────────
CREATE OR REPLACE VIEW participation_par_wilaya AS
  SELECT
    w.nom_fr AS wilaya,
    w.nom_ar AS wilaya_ar,
    v_data.election_id,
    v_data.tour,
    COUNT(vt.id) AS nb_votes_wilaya,
    COUNT(DISTINCT vt.voter_hash) AS nb_electeurs_ayant_vote,
    (SELECT COUNT(*) FROM voters vo WHERE vo.wilaya_id = w.id) AS nb_electeurs_inscrits,
    CASE
      WHEN (SELECT COUNT(*) FROM voters vo WHERE vo.wilaya_id = w.id) > 0
      THEN ROUND(
        COUNT(DISTINCT vt.voter_hash)::NUMERIC /
        (SELECT COUNT(*) FROM voters vo WHERE vo.wilaya_id = w.id) * 100, 1
      )
      ELSE 0
    END AS taux_participation
  FROM wilayas w
  CROSS JOIN (
    SELECT DISTINCT election_id, tour FROM votes WHERE is_valid = TRUE
  ) v_data
  LEFT JOIN voters voter_tbl ON voter_tbl.wilaya_id = w.id
  LEFT JOIN votes vt ON vt.voter_hash = (
    SELECT voter_hash FROM votes
    WHERE voter_hash IN (
      SELECT mv_hash FROM (
        SELECT voter_hash AS mv_hash FROM votes
        WHERE election_id = v_data.election_id AND tour = v_data.tour
      ) sub
    )
    LIMIT 1
  ) AND vt.election_id = v_data.election_id AND vt.tour = v_data.tour
  GROUP BY w.id, w.nom_fr, w.nom_ar, v_data.election_id, v_data.tour;

-- ── 7. EXPLAIN ANALYZE sur les requêtes critiques (pour vérification perfs) ────
-- Décommenter pour analyser les performances :
-- EXPLAIN ANALYZE
--   SELECT * FROM resultats_publics WHERE election_id = 'VOTRE-UUID';

-- ── 8. Rapport de l'état des index ────────────────────────────────────────────
SELECT
  schemaname,
  tablename,
  indexname,
  pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
  idx_scan                                      AS nb_utilisations
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY pg_relation_size(indexrelid) DESC;
