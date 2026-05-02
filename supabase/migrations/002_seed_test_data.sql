-- ══════════════════════════════════════════════════════════════════════════════
-- MauriVote — Migration 002 : Données de référence et données de test
-- ══════════════════════════════════════════════════════════════════════════════

-- ── Wilayas de Mauritanie (13 + District Nouakchott) ─────────────────────────
INSERT INTO wilayas (code, nom_fr, nom_ar, chef_lieu) VALUES
  ('MR-01', 'Hodh Ech Chargui',      'الحوض الشرقي',            'Néma'),
  ('MR-02', 'Hodh El Gharbi',        'الحوض الغربي',            'Aïoun el-Atrouss'),
  ('MR-03', 'Assaba',                'العصابة',                  'Kiffa'),
  ('MR-04', 'Gorgol',                'كوركول',                   'Kaédi'),
  ('MR-05', 'Brakna',                'البراكنة',                 'Aleg'),
  ('MR-06', 'Trarza',                'الترارزة',                 'Rosso'),
  ('MR-07', 'Adrar',                 'آدرار',                   'Atar'),
  ('MR-08', 'Dakhlet Nouadhibou',    'داخلت نواذيبو',           'Nouadhibou'),
  ('MR-09', 'Tagant',                'تاكانت',                   'Tidjikja'),
  ('MR-10', 'Guidimagha',            'كيدماغة',                  'Sélibaby'),
  ('MR-11', 'Tiris Zemmour',         'تيرس زمور',               'Zouérat'),
  ('MR-12', 'Inchiri',               'انشيري',                   'Akjoujt'),
  ('MR-13', 'Nouakchott Nord',       'نواكشوط الشمالية',        'Nouakchott'),
  ('MR-14', 'Nouakchott Ouest',      'نواكشوط الغربية',         'Nouakchott'),
  ('MR-15', 'Nouakchott Sud',        'نواكشوط الجنوبية',        'Nouakchott');

-- ── Communes test (Nouakchott uniquement pour les tests) ─────────────────────
WITH w_nord AS (SELECT id FROM wilayas WHERE code = 'MR-13'),
     w_ouest AS (SELECT id FROM wilayas WHERE code = 'MR-14'),
     w_sud AS (SELECT id FROM wilayas WHERE code = 'MR-15')
INSERT INTO communes (code, nom_fr, nom_ar, wilaya_id) VALUES
  ('NKT-001', 'Tevragh-Zeina',  'تفرغ زينة',   (SELECT id FROM w_ouest)),
  ('NKT-002', 'Ksar',           'القصر',         (SELECT id FROM w_nord)),
  ('NKT-003', 'Sebkha',         'السبخة',        (SELECT id FROM w_sud)),
  ('NKT-004', 'El Mina',        'الميناء',       (SELECT id FROM w_sud)),
  ('NKT-005', 'Arafat',         'عرفات',         (SELECT id FROM w_sud)),
  ('NKT-006', 'Riyad',          'الرياض',        (SELECT id FROM w_nord)),
  ('NKT-007', 'Teyarett',       'تيارت',         (SELECT id FROM w_nord)),
  ('NKT-008', 'Toujounine',     'توجنين',        (SELECT id FROM w_nord)),
  ('NKT-009', 'Dar Naim',       'دار النعيم',    (SELECT id FROM w_nord));

-- ── Bureaux de vote test ──────────────────────────────────────────────────────
WITH c_tevragh AS (SELECT id FROM communes WHERE code = 'NKT-001'),
     c_ksar AS (SELECT id FROM communes WHERE code = 'NKT-002'),
     c_sebkha AS (SELECT id FROM communes WHERE code = 'NKT-003'),
     w_ouest AS (SELECT id FROM wilayas WHERE code = 'MR-14'),
     w_nord AS (SELECT id FROM wilayas WHERE code = 'MR-13'),
     w_sud AS (SELECT id FROM wilayas WHERE code = 'MR-15')
INSERT INTO bureaux_vote
    (code_bureau, nom, commune_id, wilaya_id, adresse, latitude, longitude, capacite) VALUES
  ('NKT-001-001', 'École Tevragh-Zeina A',
    (SELECT id FROM c_tevragh), (SELECT id FROM w_ouest),
    'Rue des Ambassades, Tevragh-Zeina', 18.0735, -15.9582, 500),
  ('NKT-001-002', 'Lycée de Tevragh-Zeina',
    (SELECT id FROM c_tevragh), (SELECT id FROM w_ouest),
    'Avenue Gamal Abd El Nasser', 18.0781, -15.9601, 800),
  ('NKT-002-001', 'École Ksar Centre',
    (SELECT id FROM c_ksar), (SELECT id FROM w_nord),
    'Quartier Ksar, Rue Principale', 18.0896, -15.9712, 600),
  ('NKT-003-001', 'Centre Sebkha',
    (SELECT id FROM c_sebkha), (SELECT id FROM w_sud),
    'Boulevard Sebkha', 18.0532, -15.9845, 700);

-- ── Électeur de test ──────────────────────────────────────────────────────────
-- IMPORTANT : Ne pas utiliser en production !
WITH c AS (SELECT id FROM communes WHERE code = 'NKT-001'),
     w AS (SELECT id FROM wilayas WHERE code = 'MR-14'),
     b AS (SELECT id FROM bureaux_vote WHERE code_bureau = 'NKT-001-001')
INSERT INTO voters
    (nni, nom, prenom, date_naissance, sexe, commune_id, wilaya_id,
     bureau_vote_id, telephone, is_verified, is_active)
VALUES
  ('1234567890', 'TEST',  'Électeur',
    '1990-01-01', 'M',
    (SELECT id FROM c), (SELECT id FROM w),
    (SELECT id FROM b),
    '+22220000001', TRUE, TRUE),
  ('9876543210', 'TEST2', 'Électrice',
    '1995-06-15', 'F',
    (SELECT id FROM c), (SELECT id FROM w),
    (SELECT id FROM b),
    '+22220000002', TRUE, TRUE);

-- ── Élection de test (présidentielle simulée) ─────────────────────────────────
INSERT INTO elections
    (titre_fr, titre_ar, type_election, nb_tours,
     date_ouverture, date_fermeture, statut, is_public)
VALUES (
  'Élection Présidentielle Test 2026',
  'الانتخابات الرئاسية التجريبية 2026',
  'presidentielle', 2,
  NOW() - INTERVAL '1 hour',     -- Ouverte depuis 1h
  NOW() + INTERVAL '11 hours',   -- Ferme dans 11h
  'en_cours', TRUE
) RETURNING id;

-- ── Candidats de test ─────────────────────────────────────────────────────────
-- (À remplacer par l'ID réel retourné ci-dessus dans les seeds de dev)
DO $$
DECLARE
  election_id UUID;
BEGIN
  SELECT id INTO election_id FROM elections
  WHERE titre_fr = 'Élection Présidentielle Test 2026';

  IF election_id IS NOT NULL THEN
    INSERT INTO candidates
        (election_id, numero_candidat, nom, parti, parti_ar,
         couleur_parti, tour, is_active)
    VALUES
      (election_id, 1, 'Candidat Alpha', 'Parti de la Réforme',
        'حزب الإصلاح', '#1565C0', 1, TRUE),
      (election_id, 2, 'Candidat Beta', 'Rassemblement National',
        'التجمع الوطني', '#1B5E20', 1, TRUE),
      (election_id, 3, 'Candidat Gamma', 'Alliance Populaire',
        'التحالف الشعبي', '#E65100', 1, TRUE),
      (election_id, 4, 'Candidat Delta', 'Indépendant',
        'مستقل', '#4A148C', 1, TRUE);

    RAISE NOTICE 'Élection test créée avec ID: %', election_id;
  END IF;
END $$;

-- ── Vue utile pour le debug ───────────────────────────────────────────────────
-- Résumé des données de test
SELECT
  'wilayas'    AS table_name, COUNT(*) AS nb_lignes FROM wilayas
UNION ALL SELECT 'communes',     COUNT(*) FROM communes
UNION ALL SELECT 'bureaux_vote', COUNT(*) FROM bureaux_vote
UNION ALL SELECT 'voters',       COUNT(*) FROM voters
UNION ALL SELECT 'elections',    COUNT(*) FROM elections
UNION ALL SELECT 'candidates',   COUNT(*) FROM candidates;
