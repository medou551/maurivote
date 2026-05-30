# 🗳️ MauriVote — Application de Vote Électronique

[![CI/CD](https://github.com/votre-org/maurivote/actions/workflows/ci_cd.yml/badge.svg)](https://github.com/votre-org/maurivote/actions)
[![Coverage](https://codecov.io/gh/votre-org/maurivote/branch/main/graph/badge.svg)](https://codecov.io/gh/votre-org/maurivote)
[![Flutter](https://img.shields.io/badge/Flutter-3.16-blue)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-2.x-green)](https://supabase.com)

> Application de vote électronique sécurisée pour la **République Islamique de Mauritanie**.  
> Stack : Flutter · Supabase · Android Studio · Visual Studio Code

---

## 📋 Prérequis

| Outil | Version | Vérification |
|-------|---------|-------------|
| Flutter SDK | ≥ 3.16.x | `flutter --version` |
| Android Studio | ≥ 2023.1 (Hedgehog) | — |
| VS Code | ≥ 1.85 | `code --version` |
| Java JDK | 17 LTS | `java -version` |
| Git | ≥ 2.40 | `git --version` |
| Supabase CLI | ≥ 1.x | `supabase --version` |
| Node.js | ≥ 18 LTS | `node --version` |

---

## 🚀 Installation Rapide

### 1. Cloner le projet
```bash
git clone https://github.com/votre-org/maurivote.git
cd maurivote
```

### 2. Configurer l'environnement
```bash
cp .env.example .env
# Éditer .env avec vos clés Supabase, Twilio, etc.
```

### 3. Installer les dépendances
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Configurer Supabase
```bash
supabase login
supabase link --project-ref VOTRE_PROJECT_REF
supabase db push   # Applique toutes les migrations
```

### 5. Lancer l'application
```bash
flutter run -d emulator-5554
```

---

## 🏗️ Architecture

```
lib/
├── main.dart              # Point d'entrée (init Supabase, Hive, Firebase)
├── app.dart               # MaterialApp + GoRouter + thème
├── models/                # Modèles Dart (Voter, Election, Candidate, Vote...)
├── views/                 # Écrans Flutter (auth, home, vote, résultats...)
├── viewmodels/            # Providers Riverpod (état des vues)
├── services/              # Logique métier (AuthService, VoteService...)
├── widgets/               # Composants réutilisables
└── utils/                 # Thème, routeur, constantes, crypto, validators

supabase/
├── migrations/            # Scripts SQL (schéma, RLS, triggers)
├── functions/             # Edge Functions Deno (submit-vote, verify-vote)
└── seed/                  # Données de test (wilayas, élections fictives)

tests/
└── load/                  # Tests de charge k6
```

---

## 🧪 Lancer les Tests

```bash
# Tests unitaires
flutter test

# Avec couverture
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Tests d'intégration (émulateur requis)
flutter test integration_test/

# Tests de charge
cd tests/load
k6 run --env SUPABASE_URL=$SUPABASE_URL k6_vote_load_test.js
```

---

## 🔐 Sécurité

- **Authentification** : NNI + OTP SMS (+222) + Biométrie locale
- **Chiffrement du vote** : AES-256-CBC côté client, jamais en clair sur le serveur
- **Anonymisation** : HMAC-SHA256(NNI) — le vote ne peut pas être relié à l'électeur
- **Protection double vote** : Contrainte UNIQUE PostgreSQL + vérification Edge Function
- **RLS Supabase** : Accès direct à la table `votes` toujours refusé
- **Réseau** : TLS 1.3, Certificate Pinning, Cloudflare WAF

---

## 🌍 Langues Supportées

| Code | Langue | Écriture |
|------|--------|---------|
| `ar` | Arabe  | RTL (droite → gauche) |
| `fr` | Français | LTR |
| `ff` | Pulaar | LTR |

---

## 📊 Types d'Élections Supportés

- 🏛️ Présidentielle (2 tours)
- 🏟️ Législative (Assemblée Nationale, 176 sièges)
- 🏘️ Municipale / Communale
- 🗺️ Régionale (Conseils Régionaux)
- 📜 Référendum (1 tour)

---

## 📁 Variables d'Environnement

| Variable | Obligatoire | Description |
|----------|------------|-------------|
| `SUPABASE_URL` | ✅ | URL du projet Supabase |
| `SUPABASE_ANON_KEY` | ✅ | Clé publique Supabase |
| `VOTE_ENCRYPTION_SEL` | ✅ | Sel AES-256 (32+ chars, NE PAS CHANGER en prod) |
| `TWILIO_ACCOUNT_SID` | ✅ | Compte Twilio pour SMS |
| `GOOGLE_MAPS_API_KEY` | ✅ | API Google Maps (bureaux de vote) |

---

## 🗓️ Plan du Projet (30 jours)

| Sprint | Semaine | Livrable |
|--------|---------|---------|
| S1 | J1–J7 | Fondations : Auth NNI + OTP + Infrastructure Supabase |
| S2 | J8–J14 | Core : Vote chiffré + Profil + Carte bureau |
| S3 | J15–J21 | Avancé : Résultats temps réel + Multilingue + Offline |
| S4 | J22–J30 | Release : Tests UAT + APK signé |

---
              
## 📞 Contact 
+222 32055059
+222 22934767
  
---

*République Islamique de Mauritanie — Commission Électorale Nationale Indépendante*
