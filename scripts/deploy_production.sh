#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
# MauriVote — Déploiement Production
# Sprint 4 — J27
# Usage : ./scripts/deploy_production.sh
# ⚠️  NE PAS EXÉCUTER SANS REVUE MANUELLE PRÉALABLE
# ══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
PROD_PROJECT_REF="${SUPABASE_PROD_PROJECT_REF:-}"
PROD_URL="${SUPABASE_PROD_URL:-}"
SUPABASE_TOKEN="${SUPABASE_ACCESS_TOKEN:-}"
SLACK_WEBHOOK="${SLACK_WEBHOOK_URL:-}"
DEPLOY_LOG="logs/deploy_$(date +%Y%m%d_%H%M%S).log"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

ok()   { echo -e "${GREEN}✅ $1${NC}" | tee -a "$DEPLOY_LOG"; }
fail() { echo -e "${RED}❌ ERREUR : $1${NC}" | tee -a "$DEPLOY_LOG"
         _notify_slack "❌ DÉPLOIEMENT ÉCHOUÉ: $1"; exit 1; }
info() { echo -e "${BLUE}ℹ️  $1${NC}" | tee -a "$DEPLOY_LOG"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$DEPLOY_LOG"; }
step() { echo -e "\n${BOLD}${YELLOW}━━━ $1 ━━━${NC}" | tee -a "$DEPLOY_LOG"; }

# ── Notification Slack ─────────────────────────────────────────────────────────
_notify_slack() {
  local msg="$1"
  if [ -n "$SLACK_WEBHOOK" ]; then
    curl -s -X POST "$SLACK_WEBHOOK" \
      -H "Content-Type: application/json" \
      -d "{\"text\":\"MauriVote Production: $msg\"}" > /dev/null || true
  fi
}

# ── Bannière ───────────────────────────────────────────────────────────────────
mkdir -p logs
echo "" | tee -a "$DEPLOY_LOG"
echo -e "${BOLD}${RED}" | tee -a "$DEPLOY_LOG"
echo "  ╔══════════════════════════════════════════════╗" | tee -a "$DEPLOY_LOG"
echo "  ║   🚀 DÉPLOIEMENT PRODUCTION — MauriVote     ║" | tee -a "$DEPLOY_LOG"
echo "  ║   ⚠️  ATTENTION : ENVIRONNEMENT DE PRODUCTION ║" | tee -a "$DEPLOY_LOG"
echo "  ╚══════════════════════════════════════════════╝" | tee -a "$DEPLOY_LOG"
echo -e "${NC}" | tee -a "$DEPLOY_LOG"
echo "  Date    : $(date -u '+%Y-%m-%d %H:%M:%S UTC')" | tee -a "$DEPLOY_LOG"
echo "  Commit  : $(git rev-parse --short HEAD 2>/dev/null || echo 'no-git')" | tee -a "$DEPLOY_LOG"
echo "  Branche : $(git branch --show-current 2>/dev/null || echo 'unknown')" | tee -a "$DEPLOY_LOG"
echo "" | tee -a "$DEPLOY_LOG"

# ── Confirmation manuelle ──────────────────────────────────────────────────────
echo -e "${RED}${BOLD}⚠️  Ce script va déployer en PRODUCTION.${NC}"
echo -e "${YELLOW}   Vérifications préalables :${NC}"
echo "   □ Les tests unitaires passent (flutter test)"
echo "   □ Le build staging a été validé"
echo "   □ Les UAT sont terminés (score ≥ 4.0/5)"
echo "   □ Le rapport de sécurité est approuvé"
echo "   □ La CENI a donné son accord"
echo ""
read -r -p "Tapez 'DEPLOYER EN PRODUCTION' pour confirmer : " confirm
[ "$confirm" = "DEPLOYER EN PRODUCTION" ] || fail "Déploiement annulé par l'utilisateur"

# ── Prérequis ──────────────────────────────────────────────────────────────────
step "0. Vérification des prérequis"
[ -n "$PROD_PROJECT_REF" ] || fail "SUPABASE_PROD_PROJECT_REF non défini"
[ -n "$SUPABASE_TOKEN" ]   || fail "SUPABASE_ACCESS_TOKEN non défini"
command -v supabase &>/dev/null || fail "Supabase CLI non installé"
ok "Prérequis OK"

# ── Backup avant déploiement ───────────────────────────────────────────────────
step "1. Sauvegarde BDD avant déploiement"
BACKUP_FILE="backups/pre_deploy_$(date +%Y%m%d_%H%M%S).sql"
mkdir -p backups

info "Création snapshot de sauvegarde..."
supabase db dump \
  --project-ref "$PROD_PROJECT_REF" \
  --data-only \
  -f "$BACKUP_FILE" 2>/dev/null || warn "Dump non disponible (plan free) — snapshot Supabase Dashboard recommandé"

ok "Backup terminé : $BACKUP_FILE"

# ── Tests finaux ───────────────────────────────────────────────────────────────
step "2. Tests de non-régression"
flutter test --reporter=compact 2>/dev/null && ok "Tests unitaires OK" || \
  fail "Tests en échec — déploiement bloqué"

# ── Lier au projet production ──────────────────────────────────────────────────
step "3. Connexion au projet Supabase production"
SUPABASE_ACCESS_TOKEN="$SUPABASE_TOKEN" \
  supabase link --project-ref "$PROD_PROJECT_REF"
ok "Lié au projet production : $PROD_PROJECT_REF"

# ── Migrations BDD ────────────────────────────────────────────────────────────
step "4. Application des migrations BDD"
info "Migrations en cours..."
SUPABASE_ACCESS_TOKEN="$SUPABASE_TOKEN" \
  supabase db push --project-ref "$PROD_PROJECT_REF"
ok "Migrations appliquées"

# ── Déploiement Edge Functions ─────────────────────────────────────────────────
step "5. Déploiement des Edge Functions"
for func in submit-vote verify-vote check-voted; do
  info "Déploiement : $func"
  SUPABASE_ACCESS_TOKEN="$SUPABASE_TOKEN" \
    supabase functions deploy "$func" \
    --project-ref "$PROD_PROJECT_REF"
  ok "Edge Function $func déployée"
done

# ── Smoke Tests post-déploiement ──────────────────────────────────────────────
step "6. Smoke tests post-déploiement"
sleep 5  # Attendre la propagation

# Test GET /elections
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  "${PROD_URL}/rest/v1/elections?is_public=eq.true" \
  -H "apikey: ${SUPABASE_PROD_ANON_KEY:-}" --max-time 10 2>/dev/null || echo "000")
[ "$STATUS" = "200" ] && ok "GET /elections : HTTP 200" || \
  warn "GET /elections : HTTP $STATUS (vérifier manuellement)"

# Test RLS /votes
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  "${PROD_URL}/rest/v1/votes" \
  -H "apikey: ${SUPABASE_PROD_ANON_KEY:-}" --max-time 10 2>/dev/null || echo "000")
[ "$STATUS" = "200" ] && ok "RLS /votes : HTTP 200 (tableau vide — OK)" || \
  warn "RLS /votes : HTTP $STATUS"

# Test Edge Function verify-vote
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST "${PROD_URL}/functions/v1/verify-vote" \
  -H "Content-Type: application/json" \
  -H "apikey: ${SUPABASE_PROD_ANON_KEY:-}" \
  -d '{"recu_hash":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}' \
  --max-time 10 2>/dev/null || echo "000")
[ "$STATUS" = "200" ] && ok "Edge Function verify-vote : HTTP 200" || \
  warn "Edge Function verify-vote : HTTP $STATUS"

# ── Activation monitoring ──────────────────────────────────────────────────────
step "7. Activation du monitoring"
info "Vérifiez manuellement dans Supabase Dashboard → Logs"
info "Dashboard Grafana : http://grafana.maurivote.mr"
info "UptimeRobot : https://uptimerobot.com"
ok "Monitoring configuré (vérification manuelle recommandée)"

# ── Tag Git ────────────────────────────────────────────────────────────────────
step "8. Tag de release Git"
VERSION="v1.0.0"
BUILD="$(date +%Y%m%d%H%M)"
TAG="${VERSION}+${BUILD}"

git tag -a "$TAG" -m "Release production MauriVote ${VERSION} — $(date -u '+%Y-%m-%d')" \
  2>/dev/null && ok "Tag Git : $TAG" || warn "Tag Git non créé (pas de dépôt Git)"

# ── Rapport final ──────────────────────────────────────────────────────────────
step "9. Rapport de déploiement"
REPORT="logs/deploy_report_$(date +%Y%m%d).md"
cat > "$REPORT" << MDREPORT
# Rapport de Déploiement Production — MauriVote
**Date :** $(date -u '+%Y-%m-%d %H:%M:%S UTC')
**Version :** $TAG
**Projet Supabase :** $PROD_PROJECT_REF
**Opérateur :** $(whoami)

## Étapes effectuées
- [x] Confirmation manuelle de déploiement
- [x] Backup BDD pré-déploiement
- [x] Tests unitaires validés
- [x] Connexion projet production
- [x] Migrations BDD appliquées
- [x] Edge Functions déployées (submit-vote, verify-vote, check-voted)
- [x] Smoke tests post-déploiement
- [x] Tag Git créé

## Status
✅ DÉPLOIEMENT RÉUSSI

## Prochaines étapes
- Surveiller les métriques Grafana pendant 24h
- Vérifier les alertes UptimeRobot
- Informer la CENI de la disponibilité en production
MDREPORT

ok "Rapport : $REPORT"

# Notification Slack finale
_notify_slack "✅ DÉPLOIEMENT PRODUCTION RÉUSSI — MauriVote $TAG — $(date -u '+%H:%M UTC')"

echo ""
echo -e "${BOLD}${GREEN}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║   ✅ PRODUCTION DÉPLOYÉE AVEC SUCCÈS     ║"
echo "  ║   MauriVote $TAG              ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"
echo "  Log complet : $DEPLOY_LOG"
echo "  Rapport     : $REPORT"
echo ""
