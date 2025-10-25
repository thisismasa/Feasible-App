-- ============================================================================
-- COACH APP - COMPLETE SUPABASE DATABASE SCHEMA
-- ============================================================================
-- This schema supports: Users, Clients, Packages, Sessions, Bookings, Invoices
-- Run this in your Supabase SQL Editor
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 1. USERS TABLE (Trainers & Clients)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    phone TEXT,
    role TEXT NOT NULL CHECK (role IN ('trainer', 'client', 'admin')),
    photo_url TEXT,
    bio TEXT,
    specialization TEXT,
    certification TEXT,
    is_active BOOLEAN DEFAULT true,
    is_online BOOLEAN DEFAULT false,
    last_seen TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_active ON public.users(is_active);

-- ============================================================================
-- 2. TRAINER-CLIENT RELATIONSHIPS
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.trainer_clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trainer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    notes TEXT,
    UNIQUE(trainer_id, client_id)
);

CREATE INDEX IF NOT EXISTS idx_trainer_clients_trainer ON public.trainer_clients(trainer_id);
CREATE INDEX IF NOT EXISTS idx_trainer_clients_client ON public.trainer_clients(client_id);

-- ============================================================================
-- 3. PACKAGES (Training packages/memberships)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.packages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trainer_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    total_sessions INTEGER NOT NULL,
    duration_per_session INTEGER NOT NULL DEFAULT 60, -- minutes
    price DECIMAL(10, 2) NOT NULL,
    validity_days INTEGER NOT NULL DEFAULT 30,
    is_active BOOLEAN DEFAULT true,
    features JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_packages_trainer ON public.packages(trainer_id);
CREATE INDEX IF NOT EXISTS idx_packages_active ON public.packages(is_active);

-- ============================================================================
-- 4. CLIENT PACKAGES (Purchased packages)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.client_packages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    trainer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    package_id UUID REFERENCES public.packages(id) ON DELETE SET NULL,

    -- Package details (snapshot at purchase time)
    package_name TEXT NOT NULL,
    total_sessions INTEGER NOT NULL,
    sessions_used INTEGER DEFAULT 0,
    remaining_sessions INTEGER GENERATED ALWAYS AS (total_sessions - sessions_used) STORED,
    duration_per_session INTEGER NOT NULL DEFAULT 60,

    -- Pricing
    price_paid DECIMAL(10, 2) NOT NULL,
    amount_paid DECIMAL(10, 2) DEFAULT 0.0,
    payment_method TEXT,
    payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'refunded', 'partial')),

    -- Validity
    purchase_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expiry_date TIMESTAMP WITH TIME ZONE NOT NULL,

    -- Status
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'expired', 'completed', 'cancelled')),

    -- Metadata
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_client_packages_client ON public.client_packages(client_id);
CREATE INDEX IF NOT EXISTS idx_client_packages_trainer ON public.client_packages(trainer_id);
CREATE INDEX IF NOT EXISTS idx_client_packages_status ON public.client_packages(status);
CREATE INDEX IF NOT EXISTS idx_client_packages_expiry ON public.client_packages(expiry_date);

-- ============================================================================
-- 5. SESSIONS (Booked training sessions)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    trainer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    client_package_id UUID REFERENCES public.client_packages(id) ON DELETE SET NULL,

    -- Schedule
    scheduled_date TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_minutes INTEGER NOT NULL DEFAULT 60,

    -- Actual times (for completed sessions)
    actual_start_time TIMESTAMP WITH TIME ZONE,
    actual_end_time TIMESTAMP WITH TIME ZONE,
    actual_duration_minutes INTEGER,

    -- Session details
    session_type TEXT DEFAULT 'in_person' CHECK (session_type IN ('in_person', 'online', 'adhoc')),
    location TEXT,
    notes TEXT,
    workout_type TEXT, -- strength, hyrox, running, hiit, custom
    exercises_logged INTEGER DEFAULT 0,

    -- Status
    status TEXT DEFAULT 'scheduled' CHECK (status IN (
        'scheduled', 'confirmed', 'in_progress', 'completed', 'cancelled', 'no_show'
    )),

    -- Cancellation
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancellation_reason TEXT,
    cancelled_by UUID REFERENCES public.users(id),

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sessions_client ON public.sessions(client_id);
CREATE INDEX IF NOT EXISTS idx_sessions_trainer ON public.sessions(trainer_id);
CREATE INDEX IF NOT EXISTS idx_sessions_date ON public.sessions(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_sessions_status ON public.sessions(status);
CREATE INDEX IF NOT EXISTS idx_sessions_package ON public.sessions(client_package_id);

-- Index for conflict detection (trainer availability)
CREATE INDEX IF NOT EXISTS idx_sessions_trainer_date_status ON public.sessions(trainer_id, scheduled_date, status);

-- ============================================================================
-- 6. EXERCISE LOGS (Workout tracking)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.exercise_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES public.sessions(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,

    exercise_name TEXT NOT NULL,
    sets INTEGER,
    reps INTEGER,
    weight DECIMAL(10, 2),
    duration_seconds INTEGER,
    distance_meters DECIMAL(10, 2),
    notes TEXT,

    logged_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_exercise_logs_session ON public.exercise_logs(session_id);
CREATE INDEX IF NOT EXISTS idx_exercise_logs_client ON public.exercise_logs(client_id);

-- ============================================================================
-- 7. INVOICES
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    trainer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,

    invoice_number TEXT UNIQUE NOT NULL,
    issue_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    due_date TIMESTAMP WITH TIME ZONE NOT NULL,

    -- Amounts
    subtotal DECIMAL(10, 2) NOT NULL,
    tax DECIMAL(10, 2) DEFAULT 0,
    discount DECIMAL(10, 2) DEFAULT 0,
    total DECIMAL(10, 2) NOT NULL,

    -- Payment
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'overdue', 'cancelled')),
    paid_at TIMESTAMP WITH TIME ZONE,
    payment_method TEXT,

    -- Details
    notes TEXT,
    items JSONB DEFAULT '[]'::jsonb,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_invoices_client ON public.invoices(client_id);
CREATE INDEX IF NOT EXISTS idx_invoices_trainer ON public.invoices(trainer_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON public.invoices(status);
CREATE INDEX IF NOT EXISTS idx_invoices_due_date ON public.invoices(due_date);

-- ============================================================================
-- 8. SESSION REMINDERS
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.scheduled_reminders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES public.sessions(id) ON DELETE CASCADE,
    trainer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,

    reminder_type TEXT NOT NULL CHECK (reminder_type IN ('twentyFourHour', 'twoHour', 'thirtyMinute', 'custom')),
    scheduled_time TIMESTAMP WITH TIME ZONE NOT NULL,

    status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'sent', 'failed', 'cancelled')),
    sent_at TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reminders_session ON public.scheduled_reminders(session_id);
CREATE INDEX IF NOT EXISTS idx_reminders_scheduled_time ON public.scheduled_reminders(scheduled_time, status);

-- ============================================================================
-- 9. NOTIFICATION LOGS
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.session_reminders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES public.sessions(id) ON DELETE CASCADE,
    trainer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,

    reminder_type TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_session_reminders_session ON public.session_reminders(session_id);

-- ============================================================================
-- 10. RPC FUNCTIONS FOR BOOKING
-- ============================================================================

-- Function to book a session with transaction safety
CREATE OR REPLACE FUNCTION book_session_transaction(
    p_client_id UUID,
    p_trainer_id UUID,
    p_scheduled_date TIMESTAMP WITH TIME ZONE,
    p_duration INTEGER,
    p_package_id UUID,
    p_session_type TEXT DEFAULT 'in_person',
    p_location TEXT DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    v_package RECORD;
    v_conflict_count INTEGER;
    v_session_id UUID;
    v_buffer_minutes INTEGER := 15;
    v_session_start TIMESTAMP WITH TIME ZONE;
    v_session_end TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Calculate session time range with buffer
    v_session_start := p_scheduled_date - (v_buffer_minutes || ' minutes')::INTERVAL;
    v_session_end := p_scheduled_date + ((p_duration + v_buffer_minutes) || ' minutes')::INTERVAL;

    -- Check for time conflicts
    SELECT COUNT(*) INTO v_conflict_count
    FROM public.sessions
    WHERE trainer_id = p_trainer_id
      AND status NOT IN ('cancelled', 'no_show')
      AND (
          (scheduled_date >= v_session_start AND scheduled_date < v_session_end)
          OR
          (scheduled_date + (duration_minutes || ' minutes')::INTERVAL > v_session_start
           AND scheduled_date + (duration_minutes || ' minutes')::INTERVAL <= v_session_end)
      );

    IF v_conflict_count > 0 THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'TIME_CONFLICT',
            'message', 'This time slot conflicts with an existing session'
        );
    END IF;

    -- Validate package
    SELECT * INTO v_package
    FROM public.client_packages
    WHERE id = p_package_id
      AND client_id = p_client_id
      AND status = 'active'
      AND remaining_sessions > 0
      AND expiry_date > NOW();

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'INVALID_PACKAGE',
            'message', 'Package is not valid for booking'
        );
    END IF;

    -- Create session
    INSERT INTO public.sessions (
        client_id,
        trainer_id,
        client_package_id,
        scheduled_date,
        duration_minutes,
        session_type,
        location,
        notes,
        status
    ) VALUES (
        p_client_id,
        p_trainer_id,
        p_package_id,
        p_scheduled_date,
        p_duration,
        p_session_type,
        p_location,
        p_notes,
        'scheduled'
    )
    RETURNING id INTO v_session_id;

    -- Increment sessions used
    UPDATE public.client_packages
    SET sessions_used = sessions_used + 1,
        updated_at = NOW()
    WHERE id = p_package_id;

    -- Return success
    RETURN jsonb_build_object(
        'success', true,
        'session_id', v_session_id,
        'remaining_sessions', v_package.remaining_sessions - 1
    );
END;
$$;

-- Function to cancel a session and refund
CREATE OR REPLACE FUNCTION cancel_session_with_refund(
    p_session_id UUID,
    p_cancelled_by UUID,
    p_reason TEXT DEFAULT NULL,
    p_refund_session BOOLEAN DEFAULT true
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    v_session RECORD;
    v_hours_until_session NUMERIC;
BEGIN
    -- Get session details
    SELECT * INTO v_session
    FROM public.sessions
    WHERE id = p_session_id
      AND status = 'scheduled';

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Session not found or already processed'
        );
    END IF;

    -- Calculate hours until session
    v_hours_until_session := EXTRACT(EPOCH FROM (v_session.scheduled_date - NOW())) / 3600;

    -- Update session
    UPDATE public.sessions
    SET status = 'cancelled',
        cancelled_at = NOW(),
        cancellation_reason = p_reason,
        cancelled_by = p_cancelled_by,
        updated_at = NOW()
    WHERE id = p_session_id;

    -- Refund session if applicable
    IF p_refund_session AND v_session.client_package_id IS NOT NULL THEN
        UPDATE public.client_packages
        SET sessions_used = GREATEST(sessions_used - 1, 0),
            updated_at = NOW()
        WHERE id = v_session.client_package_id;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'refunded', p_refund_session,
        'hours_notice', v_hours_until_session
    );
END;
$$;

-- Function to get available time slots
CREATE OR REPLACE FUNCTION get_available_slots(
    p_trainer_id UUID,
    p_date DATE,
    p_duration INTEGER DEFAULT 60
)
RETURNS TABLE (
    slot_time TIMESTAMP WITH TIME ZONE,
    is_available BOOLEAN,
    conflict_reason TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_time TIMESTAMP WITH TIME ZONE;
    v_end_time TIMESTAMP WITH TIME ZONE;
    v_buffer_minutes INTEGER := 15;
BEGIN
    -- Business hours: 6 AM to 9 PM
    v_current_time := p_date + TIME '06:00:00';
    v_end_time := p_date + TIME '21:00:00';

    -- Generate 30-minute intervals
    RETURN QUERY
    WITH time_slots AS (
        SELECT generate_series(
            v_current_time,
            v_end_time,
            '30 minutes'::INTERVAL
        ) AS slot_time
    ),
    conflicts AS (
        SELECT
            s.scheduled_date - (v_buffer_minutes || ' minutes')::INTERVAL AS conflict_start,
            s.scheduled_date + ((s.duration_minutes + v_buffer_minutes) || ' minutes')::INTERVAL AS conflict_end,
            s.status
        FROM public.sessions s
        WHERE s.trainer_id = p_trainer_id
          AND DATE(s.scheduled_date) = p_date
          AND s.status NOT IN ('cancelled', 'no_show')
    )
    SELECT
        ts.slot_time,
        CASE
            WHEN EXISTS (
                SELECT 1 FROM conflicts c
                WHERE ts.slot_time >= c.conflict_start
                  AND ts.slot_time < c.conflict_end
            ) THEN false
            WHEN ts.slot_time + (p_duration || ' minutes')::INTERVAL > v_end_time THEN false
            WHEN ts.slot_time < NOW() + '2 hours'::INTERVAL THEN false
            ELSE true
        END AS is_available,
        CASE
            WHEN EXISTS (
                SELECT 1 FROM conflicts c
                WHERE ts.slot_time >= c.conflict_start
                  AND ts.slot_time < c.conflict_end
            ) THEN 'Booked or buffer time'
            WHEN ts.slot_time + (p_duration || ' minutes')::INTERVAL > v_end_time THEN 'Outside business hours'
            WHEN ts.slot_time < NOW() + '2 hours'::INTERVAL THEN 'Too soon (2h minimum)'
            ELSE NULL
        END AS conflict_reason
    FROM time_slots ts
    ORDER BY ts.slot_time;
END;
$$;

-- ============================================================================
-- 11. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trainer_clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.client_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercise_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;

-- Users can read their own profile
CREATE POLICY "Users can read own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- Trainers can read their clients
CREATE POLICY "Trainers can read their clients" ON public.users
    FOR SELECT USING (
        role = 'client' AND id IN (
            SELECT client_id FROM public.trainer_clients
            WHERE trainer_id = auth.uid()
        )
    );

-- Sessions: Trainers and clients can read their own sessions
CREATE POLICY "Users can read own sessions" ON public.sessions
    FOR SELECT USING (
        auth.uid() = trainer_id OR auth.uid() = client_id
    );

-- Sessions: Trainers can insert sessions
CREATE POLICY "Trainers can create sessions" ON public.sessions
    FOR INSERT WITH CHECK (auth.uid() = trainer_id);

-- Sessions: Trainers can update their sessions
CREATE POLICY "Trainers can update sessions" ON public.sessions
    FOR UPDATE USING (auth.uid() = trainer_id);

-- Packages: Everyone can read active packages
CREATE POLICY "Anyone can read active packages" ON public.packages
    FOR SELECT USING (is_active = true);

-- Client packages: Users can read their own packages
CREATE POLICY "Users can read own packages" ON public.client_packages
    FOR SELECT USING (
        auth.uid() = client_id OR auth.uid() = trainer_id
    );

-- ============================================================================
-- 12. TRIGGERS FOR UPDATED_AT
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_packages_updated_at BEFORE UPDATE ON public.packages
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_client_packages_updated_at BEFORE UPDATE ON public.client_packages
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sessions_updated_at BEFORE UPDATE ON public.sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON public.invoices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 13. SAMPLE DATA (Optional - for testing)
-- ============================================================================

-- Insert sample trainer
INSERT INTO public.users (id, email, full_name, phone, role, bio, specialization)
VALUES (
    'b8e7c1a0-1234-4567-89ab-cdef01234567'::UUID,
    'trainer@fitcoach.com',
    'John Trainer',
    '+1234567890',
    'trainer',
    'Certified personal trainer with 10 years of experience',
    'Strength Training, HYROX, Running'
) ON CONFLICT (email) DO NOTHING;

-- Insert sample packages
INSERT INTO public.packages (trainer_id, name, description, total_sessions, duration_per_session, price, validity_days)
VALUES
    (
        'b8e7c1a0-1234-4567-89ab-cdef01234567'::UUID,
        'Starter Package',
        'Perfect for beginners',
        8,
        60,
        299.99,
        30
    ),
    (
        'b8e7c1a0-1234-4567-89ab-cdef01234567'::UUID,
        'Pro Package',
        'For serious athletes',
        16,
        60,
        499.99,
        60
    ),
    (
        'b8e7c1a0-1234-4567-89ab-cdef01234567'::UUID,
        'Elite Package',
        'Maximum results',
        24,
        90,
        899.99,
        90
    )
ON CONFLICT DO NOTHING;

-- ============================================================================
-- SCHEMA COMPLETE!
-- ============================================================================
-- Next steps:
-- 1. Run this script in Supabase SQL Editor
-- 2. Update supabase_config.dart with your project URL and anon key
-- 3. Test the booking flow
-- ============================================================================
