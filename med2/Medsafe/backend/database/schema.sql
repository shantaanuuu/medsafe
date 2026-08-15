-- PostgreSQL / Supabase Schema for User Health Profiles

-- 1. Create User Health Profiles Table
CREATE TABLE IF NOT EXISTS user_health_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firebase_uid VARCHAR(255) UNIQUE NOT NULL,
    role VARCHAR(20) CHECK(role IN ('Patient', 'Caregiver')) NOT NULL,
    age INTEGER CHECK(age >= 0),
    weight_kg NUMERIC(5, 2) CHECK(weight_kg >= 0),
    sex VARCHAR(20),
    chronic_conditions JSONB DEFAULT '[]'::jsonb,
    current_medications JSONB DEFAULT '[]'::jsonb,
    allergies JSONB DEFAULT '[]'::jsonb,
    onboarding_step INTEGER DEFAULT 1 NOT NULL,
    onboarding_completed BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Create index on firebase_uid for fast lookup
CREATE INDEX IF NOT EXISTS idx_user_health_profiles_firebase_uid ON user_health_profiles(firebase_uid);

-- 3. Create trigger function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Apply trigger to user_health_profiles
DROP TRIGGER IF EXISTS trg_user_health_profiles_updated_at ON user_health_profiles;
CREATE TRIGGER trg_user_health_profiles_updated_at
    BEFORE UPDATE ON user_health_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
