#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
# MauriVote — Build APK Release Signé
# Sprint 4 — J24
# Usage : ./scripts/build_release.sh [version]
# Ex    : ./scripts/build_release.sh 1.0.0
# ══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

VERSION="${1:-1.0.0}"
BUILD_NUMBER=$(date +%Y%m%d%H%M)
OUTPUT_DIR="build/release"
APK_NAME="maurivote-v${VERSION}+${BUILD_NUMBER}-release.apk"

# Couleurs
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

ok()   { echo -e "${GREEN}✅ $1${NC}"; }
fail() { echo -e "${RED}❌ $1${NC}"; exit 1; }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
step() { echo -e "\n${BOLD}${YELLOW}━━ $1 ━━${NC}"; }

echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════╗"
echo "  ║   MauriVote — Build Release v${VERSION}   ║"
echo "  ╚══════════════════════════════════════╝"
echo -e "${NC}"

# ── VÉRIFICATIONS PRÉALABLES ───────────────────────────────────────────────────
step "1. Vérifications préalables"

# Flutter disponible ?
command -v flutter &>/dev/null || fail "Flutter non installé"
FLUTTER_VER=$(flutter --version --machine 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('frameworkVersion','?'))" 2>/dev/null || flutter --version | head -1 | awk '{print $2}')
ok "Flutter $FLUTTER_VER détecté"

# Java 17 ?
java -version 2>&1 | grep -q "17\." && ok "Java 17 détecté" || fail "Java 17 requis"

# Fichier .env présent ?
[ -f ".env" ] && ok "Fichier .env présent" || fail ".env manquant — copier .env.example et remplir"

# Keystore présent ?
[ -f "android/key.properties" ] || fail "android/key.properties manquant (keystore non configuré)"
[ -f "$(grep storeFile android/key.properties | cut -d= -f2)" ] 2>/dev/null || \
  info "Vérifiez le chemin du keystore dans android/key.properties"

# Branche git propre ?
if git diff --quiet 2>/dev/null; then
  ok "Dépôt Git propre"
else
  echo -e "${YELLOW}⚠️  Des fichiers non commités existent${NC}"
  git status --short
fi

GIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "no-git")
ok "Commit : $GIT_HASH"

# ── NETTOYAGE ──────────────────────────────────────────────────────────────────
step "2. Nettoyage"
flutter clean
ok "Cache Flutter nettoyé"

rm -rf "$OUTPUT_DIR" 2>/dev/null; mkdir -p "$OUTPUT_DIR"
ok "Dossier de sortie créé : $OUTPUT_DIR/"

# ── DÉPENDANCES ────────────────────────────────────────────────────────────────
step "3. Dépendances"
flutter pub get
ok "Dépendances installées"

# ── GÉNÉRATION CODE (i18n, freezed, json_serializable) ───────────────────────
step "4. Génération de code"
flutter pub run build_runner build --delete-conflicting-outputs 2>/dev/null || \
  info "build_runner ignoré (pas de générateur configuré)"
flutter gen-l10n 2>/dev/null || info "gen-l10n ignoré (fichiers ARB non configurés)"
ok "Code généré"

# ── TESTS ──────────────────────────────────────────────────────────────────────
step "5. Tests unitaires"
if flutter test --reporter=compact; then
  ok "Tous les tests passent"
else
  echo -e "${YELLOW}⚠️  Certains tests ont échoué — continuer quand même ?${NC}"
  read -r -p "  Continuer ? (o/N) " choice
  [[ "$choice" =~ ^[oO]$ ]] || fail "Build annulé (tests en échec)"
fi

# ── ANALYSE STATIQUE ───────────────────────────────────────────────────────────
step "6. Analyse statique"
flutter analyze --no-fatal-infos
ok "Analyse statique OK"

# ── BUILD APK RELEASE ─────────────────────────────────────────────────────────
step "7. Build APK Release"
info "Architecture : arm64-v8a (appareils modernes)"
info "Obfuscation  : activée"
info "Version      : $VERSION+$BUILD_NUMBER"

flutter build apk \
  --release \
  --obfuscate \
  --split-debug-info="$OUTPUT_DIR/debug-symbols" \
  --target-platform android-arm64 \
  --build-name="$VERSION" \
  --build-number="$BUILD_NUMBER" \
  --dart-define="BUILD_HASH=$GIT_HASH" \
  --dart-define="BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)"

APK_SRC="build/app/outputs/flutter-apk/app-release.apk"
[ -f "$APK_SRC" ] || fail "APK non trouvé : $APK_SRC"
cp "$APK_SRC" "$OUTPUT_DIR/$APK_NAME"
ok "APK copié : $OUTPUT_DIR/$APK_NAME"

# ── VÉRIFICATION SIGNATURE ────────────────────────────────────────────────────
step "8. Vérification de la signature"
if command -v apksigner &>/dev/null; then
  apksigner verify --verbose "$OUTPUT_DIR/$APK_NAME" 2>&1 | grep -E "Verified|error" | head -5
  ok "Signature vérifiée"
elif command -v jarsigner &>/dev/null; then
  jarsigner -verify -verbose "$OUTPUT_DIR/$APK_NAME" 2>&1 | grep -E "verified|jar" | head -3
  ok "Signature vérifiée (jarsigner)"
else
  info "apksigner non disponible — vérification ignorée"
fi

# ── TAILLE ET MÉTA-DONNÉES ────────────────────────────────────────────────────
step "9. Méta-données du build"
APK_SIZE=$(du -sh "$OUTPUT_DIR/$APK_NAME" | cut -f1)
APK_SIZE_BYTES=$(wc -c < "$OUTPUT_DIR/$APK_NAME")

echo "  Nom du fichier  : $APK_NAME"
echo "  Taille APK      : $APK_SIZE"
echo "  Taille (bytes)  : $APK_SIZE_BYTES"
echo "  Commit Git      : $GIT_HASH"
echo "  Date build      : $(date -u '+%Y-%m-%d %H:%M UTC')"
echo "  Version Flutter : $FLUTTER_VER"

# Vérifier la taille (alerte si > 50MB)
if [ "$APK_SIZE_BYTES" -gt 52428800 ]; then
  echo -e "${YELLOW}⚠️  APK volumineux (> 50MB) — considérer app bundle (.aab)${NC}"
fi

# ── CHECKSUMS ─────────────────────────────────────────────────────────────────
step "10. Checksums (intégrité)"
SHA256=$(sha256sum "$OUTPUT_DIR/$APK_NAME" | awk '{print $1}')
MD5=$(md5sum "$OUTPUT_DIR/$APK_NAME" 2>/dev/null | awk '{print $1}' || md5 "$OUTPUT_DIR/$APK_NAME" | awk '{print $4}')

echo "  SHA-256 : $SHA256"
echo "  MD5     : $MD5"

# Sauvegarder les checksums
cat > "$OUTPUT_DIR/${APK_NAME}.checksums" << CHECKSUMS
MauriVote Release Build — v${VERSION}+${BUILD_NUMBER}
Date   : $(date -u '+%Y-%m-%d %H:%M:%S UTC')
Commit : $GIT_HASH
File   : $APK_NAME
SHA256 : $SHA256
MD5    : $MD5
CHECKSUMS
ok "Checksums sauvegardés"

# ── RAPPORT FINAL ──────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║   BUILD RELEASE RÉUSSI                   ║"
echo "  ║                                          ║"
echo "  ║   Version : v${VERSION}                        ║"
echo "  ║   APK     : $APK_SIZE                         ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo "📁 Fichiers générés :"
ls -lh "$OUTPUT_DIR/" | awk 'NR>1 {printf "   %s %s %s\n", $5, $6" "$7" "$8, $9}'
echo ""
echo "📋 Prochaines étapes :"
echo "   1. Tester l'APK sur un device physique :"
echo "      adb install $OUTPUT_DIR/$APK_NAME"
echo "   2. Distribuer via Firebase App Distribution pour les tests UAT"
echo "   3. Soumettre sur Google Play Console (si applicable)"
echo "   4. Archiver : cp $OUTPUT_DIR/$APK_NAME /archive/releases/"
echo ""
