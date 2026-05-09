-- ==========================================
-- FICHIER : 02_seed_data.sql
-- RÔLE : Remplissage des données de test (Contexte Tunisien)
-- ==========================================

DO $$
DECLARE
    -- 1. UUIDs Pathologies
    p_celiac UUID := gen_random_uuid();
    p_hyper UUID := gen_random_uuid();
    p_diab UUID := gen_random_uuid();

    -- 2. UUIDs Lexique Scientifique
    l_e120 UUID := gen_random_uuid();
    l_e330 UUID := gen_random_uuid();
    l_sugar UUID := gen_random_uuid();
    l_salt UUID := gen_random_uuid();
    l_water UUID := gen_random_uuid();
    l_olive_oil UUID := gen_random_uuid();
    l_wheat UUID := gen_random_uuid();
    l_calcium UUID := gen_random_uuid();

    -- 3. UUIDs Historique
    h_scan1 UUID := gen_random_uuid();
    h_scan2 UUID := gen_random_uuid();
    h_scan3 UUID := gen_random_uuid();
    h_scan4 UUID := gen_random_uuid();
    h_scan5 UUID := gen_random_uuid();

    v_user_id UUID;
BEGIN
    -- Récupération d'un utilisateur de test existant
    SELECT id INTO v_user_id FROM auth.users LIMIT 1;

    -- NETTOYAGE STRICT (Cascade)
    DELETE FROM translations;
    DELETE FROM scientific_facts;
    DELETE FROM history_details;
    DELETE FROM history;
    DELETE FROM lexicon_pathologies;
    DELETE FROM pathologies;
    DELETE FROM scientific_lexicon;
    -- user_watchlist est ignorée (reste intacte et vide)

    -- PATHOLOGIES
    INSERT INTO pathologies (id, technical_code) VALUES 
        (p_celiac, 'celiac'), (p_hyper, 'hypertension'), (p_diab, 'diabetes_t2');

    INSERT INTO translations (parent_id, language_code, field_name, content) VALUES
        (p_celiac, 'fr', 'name', 'Maladie Cœliaque'), (p_celiac, 'ar', 'name', 'الحساسية من القمح'),
        (p_celiac, 'fr', 'description', 'Intolérance permanente au gluten nécessitant un régime strict.'),
        (p_hyper, 'fr', 'name', 'Hypertension'), (p_hyper, 'ar', 'name', 'ارتفاع ضغط الدم'),
        (p_diab, 'fr', 'name', 'Diabète Type 2'), (p_diab, 'ar', 'name', 'السكري صنف 2');

    -- LEXIQUE SCIENTIFIQUE
    INSERT INTO scientific_lexicon (id, e_code, technical_code, status) VALUES
        (l_e120, 'E120', 'carmin', 'validated'),
        (l_e330, 'E330', 'acid_citric', 'validated'),
        (l_sugar, NULL, 'sugar', 'validated'),
        (l_salt, NULL, 'salt', 'validated'),
        (l_water, NULL, 'water', 'validated'),
        (l_olive_oil, NULL, 'olive_oil', 'validated'),
        (l_wheat, NULL, 'wheat_flour', 'validated'),
        (l_calcium, NULL, 'calcium', 'validated');

    -- TRADUCTIONS (Tous les champs utilisés)
    -- E120
    INSERT INTO translations (parent_id, language_code, field_name, content) VALUES
        (l_e120, 'fr', 'name', 'Carmin'), (l_e120, 'ar', 'name', 'كارمين'),
        (l_e120, 'fr', 'generic_name', 'Colorant alimentaire rouge'),
        (l_e120, 'fr', 'description', 'Colorant naturel.'),
        (l_e120, 'fr', 'unit', 'Milligramme (mg)');

    -- Sel
    INSERT INTO translations (parent_id, language_code, field_name, content) VALUES
        (l_salt, 'fr', 'name', 'Sel'), (l_salt, 'ar', 'name', 'ملح'),
        (l_salt, 'fr', 'generic_name', 'Chlorure de sodium'),
        (l_salt, 'fr', 'description', 'Exhausteur de goût.'),
        (l_salt, 'fr', 'unit', 'Gramme (g)');

    -- Autres Ingrédients
    INSERT INTO translations (parent_id, language_code, field_name, content) VALUES
        (l_sugar, 'fr', 'name', 'Sucre'), (l_wheat, 'fr', 'name', 'Farine de blé'),
        (l_olive_oil, 'fr', 'name', 'Huile d''olive'), (l_e330, 'fr', 'name', 'Acide citrique'),
        (l_calcium, 'fr', 'name', 'Calcium'), (l_water, 'fr', 'name', 'Eau');

    -- SCIENTIFIC FACTS & LIENS PATHOLOGIQUES
    INSERT INTO lexicon_pathologies (ingredient_id, pathology_id) VALUES
        (l_wheat, p_celiac), (l_salt, p_hyper), (l_sugar, p_diab);

    INSERT INTO scientific_facts (ingredient_id, legal_reference, fact_content) VALUES
        (l_e120, 'Arrêté ministériel du 30 mai 1996', 'Additif autorisé en Tunisie.'),
        (l_salt, 'Norme NT 16.02', 'Consommation max: 5g/jour.');

    -- HISTORIQUE (Avec dates dynamiques pour test UI)
    IF v_user_id IS NOT NULL THEN
        INSERT INTO history (id, user_id, test_type, scan_date) VALUES
            (h_scan1, v_user_id, 'label_scan', NOW()),                                  -- Today
            (h_scan2, v_user_id, 'label_scan', NOW() - INTERVAL '1 day'),               -- Yesterday
            (h_scan3, v_user_id, 'label_scan', NOW() - INTERVAL '2 days'),              -- 2 days ago
            (h_scan4, v_user_id, 'dish_scan',  NOW() - INTERVAL '1 week'),              -- 1 week ago
            (h_scan5, v_user_id, 'label_scan', NOW() - INTERVAL '1 month');             -- 1 month ago

        INSERT INTO history_details (scan_id, ingredient_id, quantity_precise, unit_code) VALUES
            -- Scan 1
            (h_scan1, l_water, NULL, NULL), (h_scan1, l_sugar, 10.5, 'unit_g'),
            -- Scan 2
            (h_scan2, l_olive_oil, 5.0, 'unit_g'), (h_scan2, l_salt, 1.5, 'unit_g'),
            -- Scan 3
            (h_scan3, l_wheat, NULL, NULL), (h_scan3, l_sugar, 25.0, 'unit_g'),
            -- Scan 4
            (h_scan4, l_wheat, NULL, NULL), (h_scan4, l_olive_oil, 15.0, 'unit_g'), (h_scan4, l_salt, 450, 'unit_mg'),
            -- Scan 5
            (h_scan5, l_water, NULL, NULL), (h_scan5, l_calcium, 45.5, 'unit_mg');
    END IF;
END $$;