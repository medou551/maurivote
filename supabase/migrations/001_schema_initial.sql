-- ══════════════════════════════════════════════════════════════════════════════
-- MauriVote — Migration 001 : Schéma complet de la base de données
-- Supabase / PostgreSQL 15
-- ══════════════════════════════════════════════════════════════════════════════

-- ── Extensions nécessaires ────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── Types ENUM personnalisés ──────────────────────────────────────────────────
CREATE TYPE election_type AS ENUM (
  'presidentielle', 'legislative', 'municipale', 'regionale', 'referendum'
);

CREATE TYPE election_status AS ENUM (
  'planifiee', 'en_cours', 'terminee', 'annulee'
);

CREATE TYPE action_type AS ENUM (
  'login', 'logout', 'vote', 'vote_fail', 'admin_create',
  'admin_update', 'rls_violation', 'otp_sent', 'otp_verified', 'export'
);

-- ══════════════════════════════════════════════════════════════════════════════
-- TABLE : wilayas (13 régions + district Nouakchott)
-- ══════════════════════════════════════════════════════════════════════════════
CREATE TABLE wilayas (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  code        VARCHAR(5)  UNIQUE NOT NULL,   -- ex: MR-01
  nom_fr      VARCHAR(100) NOT NULL,
  nom_ar      VARCHAR(100) NOT NULL,
  chef_lieu   VARCHAR(100),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ══════════════════════════════════════════════════════════════════════════════
-- TABLE : communes
-- ══════════════════════════════════════════════════════════════════════════════
CREATE TABLE communes (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  code                VARCHAR(20) UNIQUE NOT NULL,
  nom_fr              VARCHAR(200) NOT NULL,
  nom_ar              VARCHAR(200) NOT NULL,
  wilaya_id           UUID        NOT NULL REFERENCES wilayas(id),
  population_estimee  INTEGER,
  created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ══════════════════════════════════════════════════════════════════════════════
-- TABLE : bureaux_vote
-- ══════════════════════════════════════════════════════════════════════════════
CREATE TABLE bureaux_vote (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  code_bureau   VARCHAR(20) UNIQUE NOT NULL,   -- ex: NKT-001-005
  nom           VARCHAR(200) NOT NULL,
  commune_id    UUID        NOT NULL REFERENCES communes(id),
  wilaya_id     UUID        NOT NULL REFERENCES wilayas(id),
  adresse       TEXT        NOT NULL,
  latitude      DECIMAL(9,6) NOT NULL,
  longitude     DECIMAL(9,6) NOT NULL,
  capacite      INTEGER     NOT NULL CHECK (capacite > 0),
  nb_urnes      SMALLINT    DEFAULT 1,
  is_accessible BOOLEAN     DEFAULT FALSE,
  is_actif      BOOLEAN     DEFAULT TRUE,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ══════════════════════════════════════════════════════════════════════════════
-- TABLE : voters (Électeurs — synchronisé avec RAVEL)
-- ══════════════════════════════════════════════════════════════════════════════
CREATE TABLE voters (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  nni             VARCHAR(10) UNIQUE NOT NULL,    -- 10 chiffres
  nom             VARCHAR(100) NOT NULL,
  prenom          VARCHAR(100) NOT NULL,
  date_naissance  DATE        NOT NULL,
  sexe            CHAR(1)     NOT NULL CHECK (sexe IN ('M', 'F')),
  commune_id      UUID        NOT NULL REFERENCES communes(id),
  wilaya_id       UUID        NOT NULL REFERENCES wilayas(id),
  bureau_vote_id  UUID        REFERENCES bureaux_vote(id),
  telephone       VARCHAR(20) NOT NULL,            -- +222XXXXXXXX
  photo_url       TEXT,
  is_verified     BOOLEAN     DEFAULT FALSE,
  is_active       BOOLEAN     DEFAULT TRUE,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Index performance
CREATE INDEX idx_voters_nni        ON voters (nni);
CREATE INDEX idx_voters_commune    ON voters (commune_id);
CREATE INDEX idx_voters_wilaya     ON voters (wilaya_id);

-- ══════════════════════════════════════════════════════════════════════════════
-- TABLE : elections
-- ══════════════════════════════════════════════════════════════════════════════
CREATE TABLE elections (
  id              UUID              PRIMARY KEY DEFAULT gen_random_uuid(),
  titre_fr        VARCHAR(200)      NOT NULL,
  titre_ar        VARCHAR(200)      NOT NULL,
  type_election   election_type     NOT NULL,
  nb_tours        SMALLINT          DEFAULT 2 CHECK (nb_tours IN (1, 2)),
  date_ouverture  TIMESTAMPTZ       NOT NULL,
  date_fermeture  TIMESTAMPTZ       NOT NULL,
  date_resultats  TIMESTAMPTZ,
  statut          election_status   NOT NULL DEFAULT 'planifiee',
  tour_actuel     SMALLINT          DEFAULT 1,
  description_fr  TEXT,
  description_ar  TEXT,
  is_public       BOOLEAN           DEFAULT TRUE,
  created_by      UUID              REFERENCES auth.users(id),
  created_at      TIMESTAMPTZ       DEFAULT NOW(),
  -- Contrainte : la fermeture doit être après l'ouverture
  CONSTRAINT chk_dates CHECK (date_fermeture > date_ouverture)
);

CREATE INDEX idx_elections_statut ON elections (statut);
CREATE INDEX idx_elections_type   ON elections (type_election);

-- ══════════════════════════════════════════════════════════════════════════════
-- TABLE : candidates
-- ══════════════════════════════════════════════════════════════════════════════
CREATE TABLE candidates (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id     UUID        NOT NULL REFERENCES elections(id) ON DELETE CASCADE,
  numero_candidat SMALLINT    NOT NULL,
  nom             VARCHAR(200) NOT NULL,
  parti           VARCHAR(200),
  parti_ar        VARCHAR(200),
  photo_url       TEXT,
  biographie_fr   TEXT,
  biographie_ar   TEXT,
  programme_url   TEXT,
  couleur_parti   CHAR(7)     CHECK (couleur_parti ~ '^#[0-9A-Fa-f]{6}$'),
  tour            SMALLINT    DEFAULT 1,
  is_active       BOOLEAN     DEFAULT TRUE,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  -- Un numéro de candidat est unique par élection et par tour
  UNIQUE (election_id, numero_candidat, tour)
);

CREATE INDEX idx_candidates_election ON candidates (election_id);

-- ══════════════════════════════════════════════════════════════════════════════
-- TABLE : votes (données ultra-sensibles — accès direct impossible)
-- ══════════════════════════════════════════════════════════════════════════════
CREATE TABLE votes (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  voter_hash      VARCHAR(64) NOT NULL,    -- HMAC-SHA256 du NNI (irréversible)
  election_id     UUID        NOT NULL REFERENCES elections(id),
  candidate_id    UUID        NOT NULL REFERENCES candidates(id),
  tour            SMALLINT    DEFAULT 1,
  vote_chiffre    TEXT        NOT NULL,    -- Payload AES-256 chiffré
  iv              VARCHAR(32) NOT NULL,    -- Vecteur d'initialisation AES
  signature       VARCHAR(128) NOT NULL,  -- Signature HMAC du payload
  ip_hash         VARCHAR(64),            -- Hash anonymisé de l'IP
  device_hash     VARCHAR(64),
  timestamp_vote  TIMESTAMPTZ DEFAULT NOW(),
  is_valid        BOOLEAN     DEFAULT TRUE,
  recu_hash       VARCHAR(64) UNIQUE NOT NULL,  -- QR Code reçu
  -- CRITIQUE : Un électeur ne peut voter qu'une fois par tour par élection
  CONSTRAINT unique_vote_per_voter_tour
    UNIQUE (voter_hash, election_id, tour)
);

-- Index performance et sécurité
CREATE INDEX idx_votes_election    ON votes (election_id);
CREATE INDEX idx_votes_recu_hash   ON votes (recu_hash);
CREATE INDEX idx_votes_voter_hash  ON votes (voter_hash);

-- ══════════════════════════════════════════════════════════════════════════════
-- TABLE : resultats (officiels — mis à jour par trigger)
-- ══════════════════════════════════════════════════════════════════════════════
CREATE TABLE resultats (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id       UUID        NOT NULL REFERENCES elections(id),
  candidate_id      UUID        NOT NULL REFERENCES candidates(id),
  tour              SMALLINT    DEFAULT 1,
  nb_votes          INTEGER     DEFAULT 0,
  pourcentage       DECIMAL(5,2) DEFAULT 0.0,
  nb_bulletins_nuls INTEGER     DEFAULT 0,
  valide_ceni       BOOLEAN     DEFAULT FALSE,
  valide_cc         BOOLEAN     DEFAULT FALSE,
  publie_at         TIMESTAMPTZ,
  updated_at        TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (election_id, candidate_id, tour)
);

-- ══════════════════════════════════════════════════════════════════════════════
-- TABLE : audit_logs (journal immuable)
-- ══════════════════════════════════════════════════════════════════════════════
CREATE TABLE audit_logs (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  action_type action_type NOT NULL,
  actor_hash  VARCHAR(64),              -- Hash anonymisé de l'acteur
  election_id UUID        REFERENCES elections(id),
  ip_hash     VARCHAR(64),
  user_agent  TEXT,
  success     BOOLEAN     DEFAULT TRUE,
  detail      JSONB,
  timestamp   TIMESTAMPTZ DEFAULT NOW(),
  server_id   VARCHAR(50)
);

CREATE INDEX idx_audit_timestamp   ON audit_logs (timestamp DESC);
CREATE INDEX idx_audit_action      ON audit_logs (action_type);

-- Rendre la table immuable (INSERT ONLY)
CREATE RULE audit_no_update AS ON UPDATE TO audit_logs DO INSTEAD NOTHING;
CREATE RULE audit_no_delete AS ON DELETE TO audit_logs DO INSTEAD NOTHING;

-- ══════════════════════════════════════════════════════════════════════════════
-- VUE : resultats_publics (agrégation sécurisée — remplace l'accès direct)
-- ══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE VIEW resultats_publics AS
  SELECT
    v.election_id,
    v.candidate_id,
    v.tour,
    COUNT(*) AS nb_votes,
    ROUND(
      COUNT(*) * 100.0 / NULLIF(SUM(COUNT(*)) OVER (
        PARTITION BY v.election_id, v.tour
      ), 0),
    2) AS pourcentage
  FROM votes v
  WHERE v.is_valid = TRUE
  GROUP BY v.election_id, v.candidate_id, v.tour;

-- ══════════════════════════════════════════════════════════════════════════════
-- TRIGGERS
-- ══════════════════════════════════════════════════════════════════════════════

-- Trigger : log automatique de chaque vote
CREATE OR REPLACE FUNCTION log_vote_attempt()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_logs (action_type, actor_hash, election_id, success, detail)
  VALUES (
    'vote',
    NEW.voter_hash,
    NEW.election_id,
    TRUE,
    jsonb_build_object('tour', NEW.tour, 'timestamp', NOW())
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_log_vote
  AFTER INSERT ON votes
  FOR EACH ROW EXECUTE FUNCTION log_vote_attempt();

-- Trigger : mise à jour automatique du champ updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_voters_updated_at
  BEFORE UPDATE ON voters
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ══════════════════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY (RLS)
-- ══════════════════════════════════════════════════════════════════════════════

-- voters
ALTER TABLE voters ENABLE ROW LEVEL SECURITY;
CREATE POLICY voter_read_own ON voters
  FOR SELECT USING (
    nni = current_setting('app.current_nni', TRUE)
  );
CREATE POLICY voter_admin ON voters
  FOR ALL USING (auth.role() = 'service_role');

-- elections
ALTER TABLE elections ENABLE ROW LEVEL SECURITY;
CREATE POLICY elections_public_read ON elections
  FOR SELECT USING (is_public = TRUE AND statut != 'annulee');
CREATE POLICY elections_admin ON elections
  FOR ALL USING (auth.role() = 'service_role');

-- candidates
ALTER TABLE candidates ENABLE ROW LEVEL SECURITY;
CREATE POLICY candidates_public_read ON candidates
  FOR SELECT USING (
    is_active = TRUE AND
    EXISTS (
      SELECT 1 FROM elections e
      WHERE e.id = election_id AND e.is_public = TRUE
    )
  );
CREATE POLICY candidates_admin ON candidates
  FOR ALL USING (auth.role() = 'service_role');

-- votes — personne ne peut lire directement
ALTER TABLE votes ENABLE ROW LEVEL SECURITY;
CREATE POLICY votes_no_direct_access ON votes
  FOR SELECT USING (FALSE);
CREATE POLICY votes_insert_auth ON votes
  FOR INSERT WITH CHECK (
    auth.role() = 'service_role'  -- Seulement via Edge Function
  );

-- resultats
ALTER TABLE resultats ENABLE ROW LEVEL SECURITY;
CREATE POLICY resultats_public_read ON resultats
  FOR SELECT USING (
    valide_ceni = TRUE AND
    EXISTS (
      SELECT 1 FROM elections e
      WHERE e.id = election_id AND e.is_public = TRUE
    )
  );
CREATE POLICY resultats_admin ON resultats
  FOR ALL USING (auth.role() = 'service_role');

-- bureaux_vote
ALTER TABLE bureaux_vote ENABLE ROW LEVEL SECURITY;
CREATE POLICY bureaux_public_read ON bureaux_vote
  FOR SELECT USING (is_actif = TRUE);

-- audit_logs — lecture admin seulement
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY audit_admin_read ON audit_logs
  FOR SELECT USING (auth.role() = 'service_role');
CREATE POLICY audit_insert ON audit_logs
  FOR INSERT WITH CHECK (TRUE);   -- Le trigger peut insérer
