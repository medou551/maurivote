/**
 * MauriVote — Tests de Charge k6 — Sprint 2 J12
 * Simule une journée électorale en Mauritanie
 *
 * Usage :
 *   k6 run \
 *     --env SUPABASE_URL=https://xxx.supabase.co \
 *     --env SUPABASE_ANON_KEY=eyJ... \
 *     --env TEST_ELECTION_ID=uuid-election \
 *     --env TEST_CANDIDATE_ID=uuid-candidat \
 *     --env TEST_JWT=eyJ... \
 *     k6_vote_load_test.js
 */

import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Counter, Trend } from 'k6/metrics';

// ── Métriques personnalisées ──────────────────────────────────────────────────
const voteSuccess    = new Rate('vote_success_rate');
const voteErrors     = new Counter('vote_errors_total');
const voteDuration   = new Trend('vote_duration_ms', true);
const electionsFetch = new Trend('elections_fetch_ms', true);
const authDuration   = new Trend('auth_duration_ms', true);

// ── Configuration des scénarios ────────────────────────────────────────────────
export const options = {
  scenarios: {
    // Scénario 1 : Charge de base (navigation)
    navigation_load: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '2m', target: 200 },   // Montée progressive
        { duration: '5m', target: 200 },   // Stabilisation
        { duration: '2m', target: 0 },     // Descente
      ],
      tags: { scenario: 'navigation' },
    },

    // Scénario 2 : Pic d'ouverture (07h00)
    pic_ouverture: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '1m', target: 500 },
        { duration: '3m', target: 1000 },
        { duration: '2m', target: 500 },
        { duration: '1m', target: 0 },
      ],
      startTime: '9m',   // Décalage après navigation_load
      tags: { scenario: 'pic_ouverture' },
    },

    // Scénario 3 : Pic de fermeture (17h30)
    pic_fermeture: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '2m', target: 1000 },
        { duration: '5m', target: 2000 },
        { duration: '2m', target: 500 },
        { duration: '1m', target: 0 },
      ],
      startTime: '25m',
      tags: { scenario: 'pic_fermeture' },
    },

    // Scénario 4 : Résultats temps réel (WebSocket simulé)
    resultats_realtime: {
      executor: 'constant-vus',
      vus: 100,
      duration: '40m',
      tags: { scenario: 'resultats' },
    },
  },

  thresholds: {
    // Latences globales
    'http_req_duration':                  ['p(95)<2000', 'p(99)<3000'],
    'http_req_duration{endpoint:vote}':   ['p(95)<1500', 'p(99)<2500'],
    'http_req_duration{endpoint:elections}': ['p(95)<800'],

    // Taux de succès
    'http_req_failed':                    ['rate<0.01'],   // < 1% d'erreurs
    'vote_success_rate':                  ['rate>0.95'],   // > 95% de succès
    'vote_errors_total':                  ['count<100'],   // < 100 erreurs au total

    // Métriques personnalisées
    'vote_duration_ms':                   ['p(95)<1500'],
    'elections_fetch_ms':                 ['p(95)<600'],
  },
};

// ── Données d'environnement ────────────────────────────────────────────────────
const BASE_URL      = __ENV.SUPABASE_URL ?? 'https://REPLACE.supabase.co';
const ANON_KEY      = __ENV.SUPABASE_ANON_KEY ?? 'REPLACE';
const ELECTION_ID   = __ENV.TEST_ELECTION_ID ?? 'REPLACE-UUID';
const CANDIDATE_ID  = __ENV.TEST_CANDIDATE_ID ?? 'REPLACE-UUID';
const TEST_JWT      = __ENV.TEST_JWT ?? 'REPLACE';

const headersAnon = {
  'apikey': ANON_KEY,
  'Content-Type': 'application/json',
};

const headersAuth = {
  'apikey': ANON_KEY,
  'Authorization': `Bearer ${TEST_JWT}`,
  'Content-Type': 'application/json',
};

// ── Utilitaires ───────────────────────────────────────────────────────────────
function randomHash(len = 64) {
  const chars = 'abcdef0123456789';
  return Array.from({ length: len }, () =>
    chars[Math.floor(Math.random() * chars.length)]).join('');
}

function randomVoterHash() {
  // Chaque VU a son propre hash unique (simule un électeur différent)
  return randomHash(64);
}

// ── Fonction principale ───────────────────────────────────────────────────────
export default function () {
  const scenario = __ENV.scenario ?? 'navigation';

  // Les scénarios "résultats" font uniquement des GETs
  if (scenario === 'resultats') {
    testResultats();
  } else {
    // Mix réaliste : 70% navigation, 30% vote
    if (Math.random() < 0.7) {
      testNavigation();
    } else {
      testVote();
    }
  }
}

// ── Test : Navigation / Lecture ────────────────────────────────────────────────
function testNavigation() {
  group('Navigation', () => {
    // GET liste des élections
    const t0 = Date.now();
    const r1 = http.get(
      `${BASE_URL}/rest/v1/elections?is_public=eq.true&statut=neq.annulee&limit=20`,
      { headers: headersAnon, tags: { endpoint: 'elections' } }
    );
    electionsFetch.add(Date.now() - t0);

    check(r1, {
      'GET /elections: status 200': (r) => r.status === 200,
      'GET /elections: array reçu': (r) => {
        try { return Array.isArray(JSON.parse(r.body)); }
        catch { return false; }
      },
    });

    sleep(Math.random() * 1 + 0.5);

    // GET candidats
    const r2 = http.get(
      `${BASE_URL}/rest/v1/candidates?election_id=eq.${ELECTION_ID}&is_active=eq.true`,
      { headers: headersAnon, tags: { endpoint: 'candidates' } }
    );

    check(r2, {
      'GET /candidates: status 200': (r) => r.status === 200,
    });

    sleep(Math.random() * 2 + 1);
  });
}

// ── Test : Soumission d'un vote ───────────────────────────────────────────────
function testVote() {
  group('Vote', () => {
    const voterHash = randomVoterHash();
    const recuHash  = randomHash(64);
    const iv        = randomHash(24);
    const sig       = randomHash(64);

    const payload = JSON.stringify({
      voter_hash:   voterHash,
      election_id:  ELECTION_ID,
      candidate_id: CANDIDATE_ID,
      tour:         1,
      vote_chiffre: `MOCK_ENCRYPTED_${randomHash(32)}`,
      iv:           iv,
      signature:    sig,
      recu_hash:    recuHash,
    });

    const t0 = Date.now();
    const r = http.post(
      `${BASE_URL}/functions/v1/submit-vote`,
      payload,
      {
        headers: headersAuth,
        tags: { endpoint: 'vote' },
        timeout: '10s',
      }
    );
    const elapsed = Date.now() - t0;
    voteDuration.add(elapsed);

    const ok = r.status === 200 || r.status === 409;
    voteSuccess.add(ok);

    if (!ok) {
      voteErrors.add(1);
      console.error(`Vote error: status=${r.status}, body=${r.body?.substring(0, 100)}`);
    }

    check(r, {
      'POST /submit-vote: accepté (200) ou double vote (409)': () => ok,
      'POST /submit-vote: réponse < 1500ms': () => elapsed < 1500,
      'POST /submit-vote: body JSON valide': () => {
        try { JSON.parse(r.body); return true; }
        catch { return false; }
      },
    });

    sleep(Math.random() * 3 + 1);
  });
}

// ── Test : Résultats temps réel ───────────────────────────────────────────────
function testResultats() {
  group('Résultats', () => {
    // Polling des résultats (simule le WebSocket avec des requêtes répétées)
    const r = http.get(
      `${BASE_URL}/rest/v1/resultats_publics?election_id=eq.${ELECTION_ID}`,
      {
        headers: headersAnon,
        tags: { endpoint: 'resultats' },
      }
    );

    check(r, {
      'GET /resultats: status 200': (r) => r.status === 200,
      'GET /resultats: < 500ms': (r) => r.timings.duration < 500,
    });

    sleep(2); // Polling toutes les 2 secondes
  });
}

// ── Rapport de fin de test ─────────────────────────────────────────────────────
export function handleSummary(data) {
  const now = new Date().toISOString();
  const report = {
    timestamp: now,
    project: 'MauriVote',
    election_id: ELECTION_ID,
    summary: {
      total_requests:   data.metrics.http_reqs?.values?.count ?? 0,
      failed_requests:  data.metrics.http_req_failed?.values?.passes ?? 0,
      p95_latency_ms:   Math.round(data.metrics.http_req_duration?.values?.['p(95)'] ?? 0),
      p99_latency_ms:   Math.round(data.metrics.http_req_duration?.values?.['p(99)'] ?? 0),
      vote_success_rate: (data.metrics.vote_success_rate?.values?.rate ?? 0).toFixed(3),
      vote_errors_count: data.metrics.vote_errors_total?.values?.count ?? 0,
      avg_vote_duration_ms: Math.round(data.metrics.vote_duration_ms?.values?.avg ?? 0),
      scenarios_passed: Object.values(data.root_group?.checks ?? {})
        .filter(c => c.passes > 0).length,
    },
    thresholds_passed: !data.state.isStdErrUsed,
  };

  return {
    'tests/load/reports/k6_report.json': JSON.stringify(report, null, 2),
    stdout: `\n══ RAPPORT MauriVote k6 ══\n${JSON.stringify(report.summary, null, 2)}\n`,
  };
}
