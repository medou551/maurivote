-- ══════════════════════════════════════════════════════════════════════════════
-- MauriVote — RESET DEV (à exécuter UNE FOIS avant les migrations)
-- Supprime tout pour repartir de zéro — NE PAS utiliser en production
-- ══════════════════════════════════════════════════════════════════════════════

-- Triggers
DROP TRIGGER IF EXISTS trg_log_vote        ON votes;
DROP TRIGGER IF EXISTS trg_voters_updated_at ON voters;

-- Fonctions
DROP FUNCTION IF EXISTS log_vote_attempt()         CASCADE;
DROP FUNCTION IF EXISTS update_updated_at()        CASCADE;
DROP FUNCTION IF EXISTS send_sms_hook(jsonb)       CASCADE;

-- Vue
DROP VIEW IF EXISTS resultats_publics CASCADE;

-- Tables (ordre inverse des dépendances)
DROP TABLE IF EXISTS audit_logs  CASCADE;
DROP TABLE IF EXISTS resultats   CASCADE;
DROP TABLE IF EXISTS votes       CASCADE;
DROP TABLE IF EXISTS candidates  CASCADE;
DROP TABLE IF EXISTS elections   CASCADE;
DROP TABLE IF EXISTS voters      CASCADE;
DROP TABLE IF EXISTS bureaux_vote CASCADE;
DROP TABLE IF EXISTS communes    CASCADE;
DROP TABLE IF EXISTS wilayas     CASCADE;

-- Types ENUM
DROP TYPE IF EXISTS election_type   CASCADE;
DROP TYPE IF EXISTS election_status CASCADE;
DROP TYPE IF EXISTS action_type     CASCADE;

SELECT 'Reset OK — lancer maintenant les migrations 001 à 008' AS status;
