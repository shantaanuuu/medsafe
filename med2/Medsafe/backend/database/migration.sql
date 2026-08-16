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

-- 5. Create Medication Schedules Table
CREATE TABLE IF NOT EXISTS medication_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cabinet_item_id VARCHAR(255) NOT NULL,
    dependent_id UUID NULL,
    user_uid VARCHAR(255) NOT NULL,
    frequency_per_day INTEGER NOT NULL CHECK (frequency_per_day > 0),
    scheduled_times JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cabinet_item FOREIGN KEY (cabinet_item_id) REFERENCES user_medicines(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_uid FOREIGN KEY (user_uid) REFERENCES users(uid) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_medication_schedules_cabinet_item ON medication_schedules(cabinet_item_id);
CREATE INDEX IF NOT EXISTS idx_medication_schedules_user ON medication_schedules(user_uid);

-- 6. Create Medication Logs Table
CREATE TABLE IF NOT EXISTS medication_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cabinet_item_id VARCHAR(255) NOT NULL,
    dependent_id UUID NULL,
    user_uid VARCHAR(255) NOT NULL,
    dose_time VARCHAR(50) NOT NULL,
    taken_date DATE NOT NULL,
    taken BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cabinet_item FOREIGN KEY (cabinet_item_id) REFERENCES user_medicines(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_uid FOREIGN KEY (user_uid) REFERENCES users(uid) ON DELETE CASCADE,
    CONSTRAINT uq_medication_log UNIQUE (cabinet_item_id, dose_time, taken_date)
);

CREATE INDEX IF NOT EXISTS idx_medication_logs_cabinet_item ON medication_logs(cabinet_item_id);
CREATE INDEX IF NOT EXISTS idx_medication_logs_user ON medication_logs(user_uid);
CREATE INDEX IF NOT EXISTS idx_medication_logs_date ON medication_logs(taken_date);
