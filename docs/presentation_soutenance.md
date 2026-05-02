# 🎤 Présentation de Soutenance — MauriVote
## Plan des 25 slides | Durée totale : 20 min présentation + 10 min démo + 15 min questions

---

## SLIDE 1 — Couverture
**Titre :** MauriVote — Application de Vote Électronique Sécurisée
**Sous-titre :** Pour la République Islamique de Mauritanie
**Visuel :** Logo MauriVote + drapeau mauritanien + Stack technologique
**Pied de page :** [Nom] · [Institution] · Avril 2026

---

## SLIDE 2 — Sommaire
**Titre :** Plan de la présentation
**Structure :**
1. Contexte et problématique (3 min)
2. Architecture technique (3 min)
3. Fonctionnalités clés (4 min)
4. Sécurité (3 min)
5. Tests et validation (3 min)
6. Démonstration live (10 min)
7. Conclusion et perspectives (4 min)

---

## SLIDE 3 — Contexte : La Mauritanie
**Titre :** Un contexte electoral unique
**Visuels :**
- Carte de Mauritanie avec les 15 wilayas
- Infographie : 1 939 341 électeurs | 3 847 bureaux | 221 communes | 4 langues
**Points clés :**
- 1 030 700 km² — 11ème plus grand pays d'Afrique
- 40% de population rurale difficile d'accès
- Multilinguisme : Arabe (officiel) + Français + Pulaar + Soninké

---

## SLIDE 4 — Problématique
**Titre :** Pourquoi MauriVote ?
**3 défis illustrés :**
- 🗺️ **Défi géographique** : Certaines communes à 800 km de Nouakchott
- 📱 **Défi de participation** : Taux de participation ~55-65%
- 🔒 **Défi de confiance** : Accusations de fraude (2023-2024)
**Question de recherche :** Comment concevoir un système de vote électronique mobile sécurisé, multilingue et accessible en Mauritanie ?

---

## SLIDE 5 — Stack Technologique
**Titre :** Technologies choisies et justifications
**Tableau comparatif visuel :**
| | Flutter | Supabase | GitHub Actions |
|---|---|---|---|
| Performance | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Coût | 🆓 Gratuit | 🆓 Free tier | 🆓 2000 min/mois |
| Open Source | ✅ | ✅ | ✅ |

---

## SLIDE 6 — Architecture Globale
**Titre :** Architecture MVVM + Supabase
**Diagramme architecture en 4 couches :**
```
[Flutter App - MVVM]
      ↕ HTTPS/TLS 1.3
[Cloudflare CDN + WAF]
      ↕
[Supabase - EU-West Paris]
  PostgREST | Edge Functions | Realtime | Auth
      ↕
[PostgreSQL 15 + RLS]
```
**Points :** Chiffrement de bout en bout · RLS sur chaque table · Réplication BDD

---

## SLIDE 7 — Base de Données
**Titre :** Schéma BDD — 8 tables sécurisées
**Diagramme ERD simplifié** avec les tables principales
**Points forts :**
- voter_hash = HMAC-SHA256(NNI) — jamais le NNI en clair dans votes
- Contrainte UNIQUE(voter_hash, election_id, tour) — anti double vote
- audit_logs immuable (INSERT ONLY) — traçabilité totale

---

## SLIDE 8 — Authentification Multi-Facteurs
**Titre :** Flux d'authentification sécurisé
**Diagramme de séquence :**
```
Électeur → NNI (10 chiffres)
         → OTP SMS (+222, 120s, 3 tentatives max)
         → Biométrie locale (empreinte/Face ID)
         → JWT signé RS256 (1h)
```
**Chiffres :** Blocage 30 min après 3 échecs · Session timeout 15 min

---

## SLIDE 9 — Chiffrement du Vote
**Titre :** Le vote n'est jamais en clair
**Schéma de chiffrement :**
```
Candidat choisi (UUID)
    → AES-256-CBC (clé dérivée, IV aléatoire)
    → HMAC-SHA256 (signature anti-altération)
    → HTTPS/TLS 1.3 (transport)
    → Edge Function (vérification signature + unicité)
    → BDD (stockage chiffré)
```
**Garantie :** Même un administrateur Supabase ne peut pas savoir qui a voté pour qui

---

## SLIDE 10 — Internationalisation
**Titre :** MauriVote parle vos langues
**3 captures d'écran côte à côte :**
- 🇫🇷 Interface Française (LTR)
- 🇲🇷 Interface Arabe (RTL, police Cairo)
- Interface Pulaar
**Chiffres :** 3 langues × 80+ clés de traduction · Sélecteur de langue en temps réel

---

## SLIDE 11 — Mode Hors-Ligne
**Titre :** Fonctionnel même sans réseau
**Schéma de fonctionnement offline :**
```
Réseau absent → Bannière orange
             → Navigation (cache Hive)
             → Vote stocké chiffré localement
             → Réseau rétabli → Sync automatique
```
**Adapté aux zones rurales mauritaniennes (2G/3G limité)**

---

## SLIDE 12 — Sécurité — Vue d'ensemble
**Titre :** Architecture de sécurité en 5 couches
**Représentation en oignon :**
1. 🌐 Réseau : TLS 1.3 + Certificate Pinning + Cloudflare WAF
2. 🔐 Auth : NNI + OTP + Biométrie + JWT
3. 🗄️ BDD : RLS sur 8 tables + Contraintes + Triggers immuables
4. 🔒 Vote : AES-256 + HMAC + Nonce anti-replay
5. 📱 Mobile : Détection root + Screenshot prevention

---

## SLIDE 13 — Tests de Charge k6
**Titre :** Scalabilité validée — 2000 utilisateurs simultanés
**Graphique k6 :** Courbe de charge + latence p95 (simulation journée électorale)
**Tableau résultats :**
| Scénario | Users | p95 | Seuil | ✅/❌ |
|---|---|---|---|---|
| Ouverture 07h00 | 1000 | 876ms | <1500ms | ✅ |
| Fermeture 17h30 | **2000** | 1420ms | <2000ms | ✅ |
| Résultats live | 100 | 310ms | <500ms | ✅ |

---

## SLIDE 14 — Rapport Pentest
**Titre :** 0 vulnérabilité critique
**Tableau des 12 tests :**
- ✅ Injection SQL (bloquée)
- ✅ Double vote (bloqué — PostgreSQL UNIQUE)
- ✅ MITM (bloqué — Certificate Pinning)
- ✅ Bypass RLS (bloqué — USING FALSE)
- ✅ Brute force OTP (bloqué — rate limit)
- ⚠️ 2 findings mineurs (FCM, debug mode)
**Score : A- | Recommandation : ✅ Autoriser déploiement**

---

## SLIDE 15 — Tests Utilisateurs (UAT)
**Titre :** Validé par 8 Mauritaniens
**Carte de Mauritanie avec points de test :**
- Nouakchott (T01, T03, T06-diaspora)
- Kaédi (T02), Atar (T04), Rosso (T05)
- Nouadhibou (T07), Kiffa (T08)
**Score moyen UAT : 4.1/5**
**Taux flux vote complet réussi : 87.5%**

---

## SLIDE 16 — Résultats en Temps Réel
**Titre :** WebSocket Supabase Realtime
**Capture d'écran dashboard résultats :**
- Badge "EN DIRECT" animé
- Graphique camembert interactif
- Barres de progression animées
**Technologie :** Supabase Realtime WebSocket · Trigger PostgreSQL → pg_notify → client

---

## SLIDE 17 — Interface Admin CENI
**Titre :** Tableau de bord CENI complet
**Capture d'écran des 4 onglets admin :**
- Général : statistiques, élections actives, actions rapides
- Élections : liste + CRUD + gestion tours
- Électeurs : recherche NNI + import RAVEL
- Sécurité : journal audit + alertes

---

## SLIDE 18 — Pipeline CI/CD
**Titre :** Automatisation complète
**Diagramme du pipeline :**
```
Push → Tests (flutter test)
     → Analyse (flutter analyze)
     → Build (APK debug)
     → Deploy Staging (auto)
     → [Approbation manuelle]
     → Deploy Production
     → Smoke tests
     → Notification Slack
```
**3 workflows :** CI/CD + Network Validation + Security Scan (hebdomadaire)

---

## SLIDE 19 — Conformité RGPD
**Titre :** Protection des données conforme
**Tableau de conformité 9 critères :**
| Critère | Statut |
|---|---|
| Minimisation données | ✅ |
| Consentement éclairé | ✅ |
| Anonymisation vote | ✅ |
| Droit à l'oubli | ✅ |
| Chiffrement | ✅ |
| Journaux audit | ✅ |
| Politique rétention | ✅ |
| DPO désigné | ⏳ (CENI) |

---

## SLIDE 20 — Métriques du Projet
**Titre :** Bilan quantitatif du projet
**Infographie chiffres-clés :**
- 📁 **62** fichiers de code produits
- 📝 **~12 000** lignes de code
- 🧪 **110** tests unitaires
- 📱 **13** écrans Flutter
- ⚡ **3** Edge Functions Deno
- 🌍 **3** langues (FR + AR + Pulaar)
- 🗄️ **5** migrations SQL
- 🔧 **3** workflows CI/CD

---

## SLIDE 21 — Démonstration
**Titre :** Démonstration Live — MauriVote
*[10 minutes de démonstration sur device physique]*

**Scénario de démo (préparé) :**
1. Connexion NNI → OTP SMS (30s)
2. Accueil → Élection présidentielle test
3. Vote → Confirmation → Reçu QR
4. Résultats temps réel (vote visible en direct)
5. Changement de langue arabe (RTL)
6. Mode hors-ligne (couper Wi-Fi → bannière)
7. Interface admin CENI (login admin)

---

## SLIDE 22 — Limites et Difficultés
**Titre :** Honnêteté intellectuelle — Limites identifiées
**3 limites principales :**
1. **Vérifiabilité de bout en bout** — Un observateur indépendant ne peut pas auditer sans accès BDD (Helios/Belenios plus rigoureux mais complexe)
2. **Dépendance à Supabase** — Risque fournisseur (mitigé par open-source et export PostgreSQL)
3. **Connectivité 2G** — Vote différé fonctionne mais latence dans les résultats

---

## SLIDE 23 — Perspectives
**Titre :** Vers MauriVote v2.0
**Roadmap en 3 horizons :**
- **v1.1 (3 mois)** : Chiffrement FCM · Play Integrity · Admin CENI complet
- **v2.0 (1 an)** : Vote par NFC · Vérifiabilité de bout en bout · Web app
- **Long terme** : Adoption officielle CENI · Extension Afrique de l'Ouest

---

## SLIDE 24 — Remerciements
**Titre :** Remerciements
- Encadrant(s) : [Noms]
- CENI Mauritanie pour les données électorales
- Les 8 testeurs UAT mauritaniens
- La communauté Flutter & Supabase (open source)
- [Institution] pour les ressources mises à disposition

---

## SLIDE 25 — Questions
**Titre :** Merci pour votre attention
**Récapitulatif :**
- MauriVote = Flutter + Supabase + MVVM + AES-256
- Score sécurité A- | Tests charge 2000 users | UAT 4.1/5
- 3 langues | Mode offline | Temps réel WebSocket

**Contact & Code source :**
- GitHub : github.com/[votre-org]/maurivote
- Email : [votre@email.mr]

**Questions du jury →**

---

## NOTES POUR LE PRÉSENTATEUR

### Timing recommandé
- Slides 1-5 : 5 min (contexte + technos)
- Slides 6-11 : 7 min (architecture + fonctionnalités)
- Slides 12-15 : 5 min (sécurité + tests)
- Slide 16-20 : 3 min (résultats)
- **Slide 21 : DÉMO 10 min** ← Préparer un device chargé + compte test
- Slides 22-25 : 5 min (limites + perspectives + questions)

### Préparation de la démo
```bash
# Avant la soutenance :
1. Charger le device à 100%
2. Activer le mode "Ne pas déranger"
3. Connecter en miroring (Scrcpy ou USB Display)
4. Ouvrir MauriVote + avoir les credentials test prêts
5. Vérifier la connexion réseau de la salle
6. Préparer une capture vidéo de secours (si réseau absent)
```

### Questions fréquentes du jury
**Q : Pourquoi Supabase et pas Firebase ?**
R : PostgreSQL avec RLS natif est idéal pour les données électorales. L'open-source garantit l'auditabilité. Le plan gratuit permet le développement sans coût.

**Q : Comment garantissez-vous l'anonymat du vote ?**
R : Le NNI n'est jamais stocké dans la table votes. Seul le voter_hash (HMAC-SHA256 irréversible) y figure. Même avec un accès direct à la BDD, il est impossible de savoir qui a voté pour qui.

**Q : Que se passe-t-il en cas de panne de Supabase le jour du vote ?**
R : Architecture de résilience : réplication BDD, RTO < 4h, mode hors-ligne sur le client. Une élection réelle nécessiterait également des mesures contractuelles SLA avec Supabase.

**Q : Est-ce légalement valide en Mauritanie ?**
R : Le cadre légal actuel ne prévoit pas le vote électronique. Ce projet est une démonstration de faisabilité technique qui nécessiterait une adaptation législative du Code Electoral avant tout déploiement réel.
