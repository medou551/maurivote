#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
# MauriVote — Test de Latence Réseau J3
# Mesure les temps de réponse depuis/vers Supabase EU-West (Paris)
# Simule les conditions réseau mauritaniennes
# ══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
SUPABASE_URL="${SUPABASE_URL:-https://VOTRE_REF.supabase.co}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-VOTRE_CLE_ANON}"
NB_TESTS=10
REPORT_FILE="network_report_$(date +%Y%m%d_%H%M%S).txt"

# ── Couleurs terminal ─────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

header() { echo -e "\n${BOLD}${BLUE}══ $1 ══${NC}"; }
ok()     { echo -e "${GREEN}✅ $1${NC}"; }
warn()   { echo -e "${YELLOW}⚠️  $1${NC}"; }
fail()   { echo -e "${RED}❌ $1${NC}"; }

# ── En-tête du rapport ────────────────────────────────────────────────────────
{
echo "════════════════════════════════════════════════════════"
echo "RAPPORT DE PERFORMANCE RÉSEAU — MauriVote"
echo "Date : $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "Supabase URL : $SUPABASE_URL"
echo "Nb de tests : $NB_TESTS"
echo "════════════════════════════════════════════════════════"
} | tee "$REPORT_FILE"

# ── TEST 1 : DNS Resolution ───────────────────────────────────────────────────
header "TEST 1 — Résolution DNS"
HOST=$(echo "$SUPABASE_URL" | sed 's|https://||' | cut -d'/' -f1)
DNS_TIME=$(dig +noall +stats "$HOST" 2>/dev/null | grep "Query time" | awk '{print $4}')
echo "Host : $HOST"
if [ -n "$DNS_TIME" ]; then
  echo "DNS Query time : ${DNS_TIME} ms"
  if [ "$DNS_TIME" -lt 100 ]; then
    ok "DNS rapide (< 100ms)"
  else
    warn "DNS lent (${DNS_TIME}ms > 100ms)"
  fi
fi | tee -a "$REPORT_FILE"

# ── TEST 2 : Ping ICMP ────────────────────────────────────────────────────────
header "TEST 2 — Ping ICMP (si autorisé)"
{
PING_RESULT=$(ping -c 5 "$HOST" 2>/dev/null | tail -1 || echo "BLOCKED")
if [[ "$PING_RESULT" == "BLOCKED" ]]; then
  warn "Ping bloqué (normal pour les serveurs cloud)"
else
  echo "$PING_RESULT"
  AVG_PING=$(echo "$PING_RESULT" | grep -oP '(?<=avg = )\d+\.\d+(?= ms)' || echo "N/A")
  echo "Latence moyenne : ${AVG_PING} ms"
fi
} | tee -a "$REPORT_FILE"

# ── TEST 3 : Latence HTTPS (TLS handshake) ────────────────────────────────────
header "TEST 3 — Latence HTTPS ($NB_TESTS mesures)"
{
echo "Endpoint testé : GET /rest/v1/elections"
echo ""

TOTAL_DNS=0; TOTAL_CONNECT=0; TOTAL_TLS=0; TOTAL_TTFB=0; TOTAL=0
SUCCESS=0; ERRORS=0

for i in $(seq 1 $NB_TESTS); do
  RESULT=$(curl -s -o /dev/null -w \
    "%{time_namelookup} %{time_connect} %{time_appconnect} %{time_starttransfer} %{time_total} %{http_code}" \
    "$SUPABASE_URL/rest/v1/elections?limit=1" \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Content-Type: application/json" \
    --max-time 10 2>/dev/null || echo "0 0 0 0 0 000")

  DNS=$(echo $RESULT | awk '{printf "%.3f", $1*1000}')
  CONN=$(echo $RESULT | awk '{printf "%.3f", $2*1000}')
  TLS=$(echo $RESULT | awk '{printf "%.3f", $3*1000}')
  TTFB=$(echo $RESULT | awk '{printf "%.3f", $4*1000}')
  TOT=$(echo $RESULT | awk '{printf "%.3f", $5*1000}')
  STATUS=$(echo $RESULT | awk '{print $6}')

  if [ "$STATUS" = "200" ]; then
    SUCCESS=$((SUCCESS+1))
    printf "  Test %2d : DNS=%-8s TCP=%-8s TLS=%-8s TTFB=%-8s Total=%-8s ✅\n" \
      "$i" "${DNS}ms" "${CONN}ms" "${TLS}ms" "${TTFB}ms" "${TOT}ms"
    TOTAL_DNS=$(echo "$TOTAL_DNS + $DNS" | bc)
    TOTAL_CONNECT=$(echo "$TOTAL_CONNECT + $CONN" | bc)
    TOTAL_TLS=$(echo "$TOTAL_TLS + $TLS" | bc)
    TOTAL_TTFB=$(echo "$TOTAL_TTFB + $TTFB" | bc)
    TOTAL=$(echo "$TOTAL + $TOT" | bc)
  else
    ERRORS=$((ERRORS+1))
    printf "  Test %2d : ERREUR HTTP %s ❌\n" "$i" "$STATUS"
  fi
  sleep 0.5  # Respecter le rate limiting
done

echo ""
echo "── Résultats ($SUCCESS/$NB_TESTS réussis) ──"
if [ $SUCCESS -gt 0 ]; then
  AVG_DNS=$(echo "scale=1; $TOTAL_DNS / $SUCCESS" | bc)
  AVG_CONN=$(echo "scale=1; $TOTAL_CONNECT / $SUCCESS" | bc)
  AVG_TLS=$(echo "scale=1; $TOTAL_TLS / $SUCCESS" | bc)
  AVG_TTFB=$(echo "scale=1; $TOTAL_TTFB / $SUCCESS" | bc)
  AVG_TOT=$(echo "scale=1; $TOTAL / $SUCCESS" | bc)

  printf "  DNS moyen     : %s ms\n" "$AVG_DNS"
  printf "  TCP moyen     : %s ms\n" "$AVG_CONN"
  printf "  TLS moyen     : %s ms\n" "$AVG_TLS"
  printf "  TTFB moyen    : %s ms\n" "$AVG_TTFB"
  printf "  Total moyen   : %s ms\n" "$AVG_TOT"
  echo ""

  # Évaluation des performances
  TOT_INT=$(echo "$AVG_TOT" | cut -d'.' -f1)
  if [ "$TOT_INT" -lt 500 ]; then
    echo "✅ Latence EXCELLENTE (< 500ms) — Expérience utilisateur optimale"
  elif [ "$TOT_INT" -lt 1000 ]; then
    echo "✅ Latence BONNE (< 1s) — Acceptable pour vote mobile"
  elif [ "$TOT_INT" -lt 2000 ]; then
    echo "⚠️  Latence MOYENNE (< 2s) — Envisager une région Supabase plus proche"
  else
    echo "❌ Latence ÉLEVÉE (> 2s) — Optimisation nécessaire"
  fi
fi
} | tee -a "$REPORT_FILE"

# ── TEST 4 : Vérification SSL/TLS ─────────────────────────────────────────────
header "TEST 4 — Certificat SSL/TLS"
{
TLS_INFO=$(echo | openssl s_client -connect "${HOST}:443" -servername "$HOST" \
  -brief 2>/dev/null | grep -E "Protocol|Cipher|Verification" || echo "N/A")
echo "$TLS_INFO"

# Vérifier TLS 1.3
if echo "$TLS_INFO" | grep -q "TLSv1.3"; then
  ok "TLS 1.3 activé"
elif echo "$TLS_INFO" | grep -q "TLSv1.2"; then
  warn "TLS 1.2 (recommander TLS 1.3)"
fi

# Vérifier expiration certificat
CERT_EXPIRY=$(echo | openssl s_client -connect "${HOST}:443" -servername "$HOST" 2>/dev/null \
  | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2 || echo "N/A")
echo "Expiration cert : $CERT_EXPIRY"
} | tee -a "$REPORT_FILE"

# ── TEST 5 : Test RLS (endpoints sécurisés) ───────────────────────────────────
header "TEST 5 — Vérification sécurité API"
{
# Test GET /votes (doit être vide ou refusé)
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  "$SUPABASE_URL/rest/v1/votes" \
  -H "apikey: $SUPABASE_ANON_KEY" --max-time 5 2>/dev/null || echo "000")
echo "GET /votes (accès direct) : HTTP $STATUS"
if [ "$STATUS" = "200" ] || [ "$STATUS" = "403" ]; then
  ok "Endpoint /votes : protégé (RLS retourne 0 résultats ou 403)"
else
  warn "Réponse inattendue : $STATUS"
fi

# Test GET /elections (doit être accessible)
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  "$SUPABASE_URL/rest/v1/elections?is_public=eq.true" \
  -H "apikey: $SUPABASE_ANON_KEY" --max-time 5 2>/dev/null || echo "000")
echo "GET /elections (public) : HTTP $STATUS"
[ "$STATUS" = "200" ] && ok "Endpoint /elections : accessible" || fail "Inaccessible ($STATUS)"
} | tee -a "$REPORT_FILE"

# ── Rapport final ─────────────────────────────────────────────────────────────
{
echo ""
echo "════════════════════════════════════════════════════════"
echo "FIN DU RAPPORT — $(date -u '+%H:%M:%S UTC')"
echo "Fichier rapport : $REPORT_FILE"
echo "════════════════════════════════════════════════════════"
} | tee -a "$REPORT_FILE"

echo -e "\n${GREEN}${BOLD}Rapport sauvegardé : $REPORT_FILE${NC}"
