-- ==========================================
-- FICHIER : 01_final_schema.sql
-- RÔLE : Structure complète OCR + LLM + Traçabilité
-- ==========================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. ENUMERATIONS
CREATE TYPE test_type_enum AS ENUM ('label_scan', 'dish_scan');
CREATE TYPE validation_status_enum AS ENUM ('pending', 'validated', 'rejected');
CREATE TYPE translation_field_type AS ENUM ('name', 'description', 'generic_name', 'unit', 'raw_text','fact_content','legal_reference');

-- 3. SCIENTIFIC DATA (Referential)
CREATE TABLE pathologies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    technical_code TEXT UNIQUE NOT NULL -- ex: 'celiac', 'diabetic'
);

CREATE TABLE scientific_lexicon (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    e_code TEXT UNIQUE, -- ex: 'E124'
    technical_code TEXT UNIQUE NOT NULL, 
    source_type TEXT DEFAULT 'official', -- 'official' or 'ai_discovered'
    status validation_status_enum DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE scientific_facts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ingredient_id UUID REFERENCES scientific_lexicon(id) ON DELETE CASCADE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lexicon_pathologies (
    ingredient_id UUID REFERENCES scientific_lexicon(id) ON DELETE CASCADE,
    pathology_id UUID REFERENCES pathologies(id) ON DELETE CASCADE,
    PRIMARY KEY (ingredient_id, pathology_id)
);

-- 4. USER DATA (INPDP & Law 54)
CREATE TABLE user_profiles (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    language_pref TEXT DEFAULT 'fr', -- fr, ar, en, ar_tn
    is_admin BOOLEAN DEFAULT false,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- AJOUT : Table des préférences (Watchlist) pour les alertes personnalisées
CREATE TABLE user_watchlist (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    ingredient_id UUID REFERENCES scientific_lexicon(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, ingredient_id)
);
-- 5. HISTORY & SESSION SYSTEM (Multi-face support)
CREATE TABLE history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    session_id UUID NOT NULL, -- Pour lier plusieurs captures d'un même produit
    test_type test_type_enum NOT NULL,
    image_url TEXT, -- URL de l'image stockée dans Supabase Storage
    scan_date TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE history_details (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scan_id UUID REFERENCES history(id) ON DELETE CASCADE,
    ingredient_id UUID REFERENCES scientific_lexicon(id),
    quantity_precise NUMERIC,
    unit_code TEXT, -- ex: 'unit_g', 'unit_ml'
    is_estimated BOOLEAN DEFAULT false, -- Indique si la valeur vient du LLM ou de l'étiquette
    CONSTRAINT unit_code_format CHECK (unit_code IS NULL OR unit_code ~ '^unit_')
);

-- 6. TRANSLATIONS (Including Tunisian Arabic)
CREATE TABLE translations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id UUID NOT NULL, -- ID de l'ingrédient ou du scan
    parent_type TEXT NOT NULL, -- 'scientific_lexicon' ou 'history'
    language_code TEXT NOT NULL CHECK (language_code IN ('fr', 'ar', 'en', 'ar_tn')),
    field_name translation_field_type NOT NULL,
    content TEXT NOT NULL,
    is_verified BOOLEAN DEFAULT false,
    CONSTRAINT unique_translation_entry UNIQUE (parent_id, language_code, field_name)
);

-- 7. AI STAGING & TRACEABILITY (The Audit Trail)
CREATE TABLE ai_suggestions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scan_id UUID REFERENCES history(id) ON DELETE SET NULL, -- LIEN DE TRAÇABILITÉ
    model_name TEXT, -- ex: 'gemini-1.5-flash'
    target_table TEXT DEFAULT 'scientific_lexicon',
    payload JSONB, -- Stocke l'analyse brute du LLM
    confidence NUMERIC CHECK (confidence >= 0 AND confidence <= 1),
    status validation_status_enum DEFAULT 'pending',
    validated_by UUID REFERENCES auth.users(id), -- Admin qui a validé
    validated_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. INDEXES (Performance)
CREATE INDEX idx_translations_lookup ON translations (parent_id, language_code, field_name);
CREATE INDEX idx_history_session ON history(session_id);
CREATE INDEX idx_ai_traceability ON ai_suggestions(scan_id, status);

-- 9. RLS POLICIES (Security)
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own profile" ON user_profiles FOR SELECT USING (auth.uid() = user_id);

ALTER TABLE history ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own history" ON history FOR SELECT USING (auth.uid() = user_id);
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own profile" ON user_profiles FOR SELECT USING (auth.uid() = user_id);

-- AJOUT : Sécurité pour la Watchlist
ALTER TABLE user_watchlist ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own watchlist" ON user_watchlist FOR ALL USING (auth.uid() = user_id);
