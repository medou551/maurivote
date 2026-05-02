#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
# MauriVote — Configuration des secrets GitHub Actions
# Prérequis : GitHub CLI (gh) installé et authentifié
# Usage : ./secrets_setup.sh <GITHUB_REPO>
# Ex    : ./secrets_setup.sh mon-org/maurivote
# ══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

REPO="${1:-}"
if [ -z "$REPO" ]; then
  echo "❌ Usage : $0 <org/repo>"
  echo "   Ex    : $0 mon-org/maurivote"
  exit 1
fi

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✅ $1${NC}"; }
fail() { echo -e "${RED}❌ $1${NC}"; }
ask()  { echo -e "${YELLOW}❓ $1${NC}"; }

echo "══════════════════════════════════════════"
echo "  Configuration Secrets — $REPO"
echo "══════════════════════════════════════════"
echo ""

# ── Vérification GitHub CLI ────────────────────────────────────────────────────
if ! command -v gh &>/dev/null; then
  fail "GitHub CLI non installé. Installez via : https://cli.github.com"
  exit 1
fi

if ! gh auth status &>/dev/null; then
  fail "GitHub CLI non authentifié. Lancez : gh auth login"
  exit 1
fi
ok "GitHub CLI prêt"

# ── Fonction pour définir un secret ──────────────────────────────────────────
set_secret() {
  local name="$1"
  local prompt="$2"
  local value=""

  ask "$prompt"
  read -s -r value
  echo ""

  if [ -z "$value" ]; then
    echo "  ⏭  Ignoré (valeur vide)"
    return
  fi

  echo "$value" | gh secret set "$name" --repo "$REPO" --body -
  ok "Secret '$name' défini"
}

echo ""
echo "── Supabase DEV ──────────────────────────────────"
set_secret "SUPABASE_DEV_URL"          "URL Supabase DEV (https://xxx.supabase.co) :"
set_secret "SUPABASE_DEV_ANON_KEY"     "Clé anon Supabase DEV :"
set_secret "SUPABASE_DEV_PROJECT_REF"  "Project Ref Supabase DEV (xxxxxxxxxxxx) :"

echo ""
echo "── Supabase STAGING ──────────────────────────────"
set_secret "SUPABASE_STAGING_URL"         "URL Supabase STAGING :"
set_secret "SUPABASE_STAGING_ANON_KEY"    "Clé anon Supabase STAGING :"
set_secret "SUPABASE_STAGING_PROJECT_REF" "Project Ref STAGING :"

echo ""
echo "── Supabase PRODUCTION ───────────────────────────"
set_secret "SUPABASE_PROD_URL"         "URL Supabase PRODUCTION :"
set_secret "SUPABASE_PROD_ANON_KEY"    "Clé anon PRODUCTION :"
set_secret "SUPABASE_PROD_PROJECT_REF" "Project Ref PRODUCTION :"

echo ""
echo "── Supabase Access Token (global) ────────────────"
set_secret "SUPABASE_ACCESS_TOKEN" "Token d'accès Supabase CLI (depuis app.supabase.com/account/tokens) :"

echo ""
echo "── Chiffrement & Sécurité ────────────────────────"
set_secret "TEST_ENCRYPTION_SEL" "Sel de chiffrement pour tests (32+ chars) :"

echo ""
echo "── Google Maps ───────────────────────────────────"
set_secret "GOOGLE_MAPS_API_KEY" "Clé Google Maps API :"

echo ""
echo "── Notifications ─────────────────────────────────"
set_secret "SLACK_WEBHOOK_URL" "URL Webhook Slack (pour alertes CI/CD) :"

echo ""
echo "── Codecov ───────────────────────────────────────"
set_secret "CODECOV_TOKEN" "Token Codecov (depuis app.codecov.io) :"

echo ""
echo "── Tests de charge k6 ────────────────────────────"
set_secret "TEST_ELECTION_ID"  "UUID élection de test (pour k6) :"
set_secret "TEST_CANDIDATE_ID" "UUID candidat de test (pour k6) :"

echo ""
echo "══════════════════════════════════════════"
echo "Configuration terminée !"
echo ""
echo "Vérifier les secrets :"
echo "  gh secret list --repo $REPO"
echo ""
echo "Déclencher un test du pipeline :"
echo "  gh workflow run ci_cd.yml --repo $REPO"
echo "══════════════════════════════════════════"
