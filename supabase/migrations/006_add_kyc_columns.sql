-- ══════════════════════════════════════════════════════════════════════════════
-- Migration 006 — Colonnes KYC + Vérification identité
-- À exécuter dans Supabase SQL Editor (DEV + PROD)
-- ══════════════════════════════════════════════════════════════════════════════

-- Ajouter colonnes KYC à la table voters
ALTER TABLE voters
  ADD COLUMN IF NOT EXISTS kyc_completed  BOOLEAN     DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS kyc_date       TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS cni_recto_url  TEXT,
  ADD COLUMN IF NOT EXISTS cni_verso_url  TEXT,
  ADD COLUMN IF NOT EXISTS selfie_url     TEXT,
  ADD COLUMN IF NOT EXISTS basma_verified BOOLEAN     DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS houwiyeti_id   TEXT,
  ADD COLUMN IF NOT EXISTS account_type   VARCHAR(20) DEFAULT 'user';
  -- account_type: 'user', 'admin', 'ceni_agent'

-- Index pour les recherches par type de compte
CREATE INDEX IF NOT EXISTS idx_voters_account_type
  ON voters (account_type);

CREATE INDEX IF NOT EXISTS idx_voters_kyc
  ON voters (kyc_completed, is_verified);

-- Bucket Storage pour les documents KYC
-- (À créer dans Supabase Dashboard → Storage → New Bucket)
-- Nom : kyc-documents (private)
-- Nom : voter-photos (public)

-- Vue pour les admins — liste des utilisateurs vérifiés
CREATE OR REPLACE VIEW voters_verified AS
  SELECT
    id,
    nni,
    nom,
    prenom,
    telephone,
    kyc_completed,
    kyc_date,
    basma_verified,
    is_verified,
    account_type,
    created_at
  FROM voters
  WHERE is_active = TRUE
  ORDER BY created_at DESC;

-- Policy RLS pour la vue
ALTER TABLE voters ENABLE ROW LEVEL SECURITY;

-- Un admin peut voir tous les voters
DO $$ BEGIN
  CREATE POLICY voters_admin_all ON voters
    FOR ALL USING (auth.role() = 'service_role');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Fonction pour promouvoir un user en admin
CREATE OR REPLACE FUNCTION promote_to_admin(voter_nni VARCHAR)
RETURNS VOID AS $$
BEGIN
  UPDATE voters
  SET account_type = 'admin'
  WHERE nni = voter_nni;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Vérification
SELECT
  COUNT(*) FILTER (WHERE kyc_completed = TRUE)  AS kyc_complets,
  COUNT(*) FILTER (WHERE is_verified = TRUE)    AS verifies,
  COUNT(*) FILTER (WHERE account_type = 'admin') AS admins,
  COUNT(*)                                       AS total
FROM voters;
