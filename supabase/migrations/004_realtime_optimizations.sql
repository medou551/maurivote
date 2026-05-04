-- ══════════════════════════════════════════════════════════════════════════════
-- MauriVote — Migration 004 FINALE : Optimisations Realtime + Index
-- ══════════════════════════════════════════════════════════════════════════════

-- ── 1. Activation Realtime ─────────────────────────────────────────────────────
ALTER TABLE resultats REPLICA IDENTITY FULL;
ALTER TABLE votes     REPLICA IDENTITY FULL;

-- ── 2. Index performance ───────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_resultats_election_tour
  ON resultats (election_id, tour, nb_votes DESC);

CREATE INDEX IF NOT EXISTS idx_votes_election_tour_valid
  ON votes (election_id, tour, is_valid)
  WHERE is_valid = TRUE;

CREATE INDEX IF NOT EXISTS idx_votes_recu_valid
  ON votes (recu_hash, is_valid)
  WHERE is_valid = TRUE;

CREATE INDEX IF NOT EXISTS idx_votes_voter_election_tour
  ON votes (voter_hash, election_id, tour)
  WHERE is_valid = TRUE;

CREATE INDEX IF NOT EXISTS idx_elections_statut_public
  ON elections (statut, is_public, date_fermeture)
  WHERE is_public = TRUE AND statut != 'annulee';

CREATE INDEX IF NOT EXISTS idx_candidates_election_active
  ON candidates (election_id, tour, is_active)
  WHERE is_active = TRUE;

-- ── 3. Fonction mise à jour automatique des résultats ─────────────────────────
CREATE OR REPLACE FUNCTION update_resultats_after_vote()
RETURNS TRIGGER AS $$
DECLARE
  total_votes INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_votes
  FROM votes
  WHERE election_id = NEW.election_id
    AND tour = NEW.tour
    AND is_valid = TRUE;

  INSERT INTO resultats (election_id, candidate_id, tour, nb_votes, pourcentage, updated_at)
  VALUES (NEW.election_id, NEW.candidate_id, NEW.tour, 1, 0, NOW())
  ON CONFLICT (election_id, candidate_id, tour)
  DO UPDATE SET
    nb_votes   = (SELECT COUNT(*) FROM votes
                  WHERE election_id = NEW.election_id
                    AND candidate_id = NEW.candidate_id
                    AND tour = NEW.tour
                    AND is_valid = TRUE),
    updated_at = NOW();

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

DROP TRIGGER IF EXISTS trg_update_resultats_on_vote ON votes;
CREATE TRIGGER trg_update_resultats_on_vote
  AFTER INSERT ON votes
  FOR EACH ROW EXECUTE FUNCTION update_resultats_after_vote();

-- ── 4. Fonction broadcast Realtime ────────────────────────────────────────────
CREATE OR REPLACE FUNCTION broadcast_resultat_update()
RETURNS TRIGGER AS $$
BEGIN
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

DROP TRIGGER IF EXISTS trg_broadcast_resultats ON resultats;
CREATE TRIGGER trg_broadcast_resultats
  AFTER INSERT OR UPDATE ON resultats
  FOR EACH ROW EXECUTE FUNCTION broadcast_resultat_update();

-- ── 5. Vue matérialisée résultats avec candidats ──────────────────────────────
DROP MATERIALIZED VIEW IF EXISTS resultats_avec_candidats;
CREATE MATERIALIZED VIEW resultats_avec_candidats AS
  SELECT
    r.election_id,
    r.candidate_id,
    r.tour,
    r.nb_votes,
    r.pourcentage,
    r.valide_ceni,
    r.valide_cc,
    r.updated_at,
    c.nom            AS candidat_nom,
    c.parti          AS candidat_parti,
    c.parti_ar       AS candidat_parti_ar,
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

-- ── 6. Rapport final — vérification ──────────────────────────────────────────
SELECT
  t.relname  AS table_name,
  i.relname  AS index_name,
  pg_size_pretty(pg_relation_size(i.oid)) AS taille
FROM pg_class t
JOIN pg_index ix ON t.oid = ix.indrelid
JOIN pg_class i  ON i.oid = ix.indexrelid
JOIN pg_namespace n ON t.relnamespace = n.oid
WHERE n.nspname = 'public'
  AND t.relkind = 'r'
ORDER BY t.relname, i.relname;