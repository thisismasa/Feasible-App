-- ============================================================================
-- CREATE SESSIONS TABLE WITH GOOGLE CALENDAR SUPPORT
-- ============================================================================
-- This creates the sessions table for booking management
-- INCLUDES google_calendar_event_id column from the start
-- ============================================================================

-- Create sessions table
CREATE TABLE IF NOT EXISTS sessions (
  -- Primary key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Foreign keys
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  package_id UUID REFERENCES client_packages(id) ON DELETE SET NULL,

  -- Schedule information
  scheduled_start TIMESTAMPTZ NOT NULL,
  scheduled_end TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL DEFAULT 'scheduled',

  -- Session details
  session_type TEXT DEFAULT 'in_person',
  location TEXT,
  notes TEXT,

  -- Actual time tracking
  actual_start_time TIMESTAMPTZ,
  actual_end_time TIMESTAMPTZ,
  actual_duration_minutes INTEGER,

  -- Cancellation info
  cancelled_at TIMESTAMPTZ,
  cancelled_by UUID REFERENCES users(id),
  cancellation_reason TEXT,

  -- Google Calendar integration
  google_calendar_event_id TEXT,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  CONSTRAINT valid_status CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled', 'no_show')),
  CONSTRAINT valid_session_type CHECK (session_type IN ('in_person', 'online', 'hybrid')),
  CONSTRAINT scheduled_end_after_start CHECK (scheduled_end > scheduled_start)
);

-- Add comment to document the table
COMMENT ON TABLE sessions IS 'Stores training session bookings with Google Calendar integration';
COMMENT ON COLUMN sessions.google_calendar_event_id IS 'Google Calendar Event ID for syncing with trainer calendar';

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_sessions_client_id ON sessions(client_id);
CREATE INDEX IF NOT EXISTS idx_sessions_trainer_id ON sessions(trainer_id);
CREATE INDEX IF NOT EXISTS idx_sessions_scheduled_start ON sessions(scheduled_start);
CREATE INDEX IF NOT EXISTS idx_sessions_status ON sessions(status);
CREATE INDEX IF NOT EXISTS idx_sessions_package_id ON sessions(package_id);
CREATE INDEX IF NOT EXISTS idx_sessions_google_calendar_event_id ON sessions(google_calendar_event_id)
  WHERE google_calendar_event_id IS NOT NULL;

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_sessions_updated_at ON sessions;
CREATE TRIGGER update_sessions_updated_at
  BEFORE UPDATE ON sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;

-- Policy: Clients can view their own sessions
CREATE POLICY "Clients can view own sessions" ON sessions
  FOR SELECT USING (
    auth.uid() = client_id
  );

-- Policy: Trainers can view sessions they're assigned to
CREATE POLICY "Trainers can view assigned sessions" ON sessions
  FOR SELECT USING (
    auth.uid() = trainer_id
  );

-- Policy: Trainers can insert sessions for their clients
CREATE POLICY "Trainers can create sessions" ON sessions
  FOR INSERT WITH CHECK (
    auth.uid() = trainer_id
  );

-- Policy: Trainers can update their sessions
CREATE POLICY "Trainers can update sessions" ON sessions
  FOR UPDATE USING (
    auth.uid() = trainer_id
  );

-- Policy: Trainers can cancel their sessions
CREATE POLICY "Trainers can cancel sessions" ON sessions
  FOR DELETE USING (
    auth.uid() = trainer_id
  );

-- Verify table was created
SELECT
  '✅ sessions table created successfully!' as status,
  COUNT(*) as column_count
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'sessions';

-- Show table structure
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'sessions'
ORDER BY ordinal_position;

-- Show indexes
SELECT
  indexname as index_name,
  indexdef as definition
FROM pg_indexes
WHERE tablename = 'sessions'
  AND schemaname = 'public'
ORDER BY indexname;

-- Final success message
SELECT '🎉 Table ready! Google Calendar integration enabled!' as message;
