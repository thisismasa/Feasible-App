-- ============================================================================
-- SUPABASE STORAGE POLICIES - Copy this entire content and paste in SQL Editor
-- ============================================================================

-- IMPORTANT: First create the buckets in Storage UI:
-- 1. Go to Storage → Create bucket "avatars" (Public: ON)
-- 2. Go to Storage → Create bucket "documents" (Public: OFF)
-- Then run this SQL to set up security policies

-- ============================================================================
-- POLICIES FOR AVATARS BUCKET (PUBLIC)
-- ============================================================================

CREATE POLICY "Authenticated users can upload avatars"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'avatars');

CREATE POLICY "Anyone can view avatars"
ON storage.objects FOR SELECT TO public
USING (bucket_id = 'avatars');

CREATE POLICY "Users can update avatars"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'avatars');

CREATE POLICY "Users can delete avatars"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'avatars');

-- ============================================================================
-- POLICIES FOR DOCUMENTS BUCKET (PRIVATE)
-- ============================================================================

CREATE POLICY "Authenticated users can upload documents"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'documents');

CREATE POLICY "Authenticated users can view documents"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'documents');

CREATE POLICY "Users can update documents"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'documents');

CREATE POLICY "Users can delete documents"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'documents');

-- ============================================================================
-- OPTIONAL: METADATA TABLE FOR TRACKING UPLOADS
-- ============================================================================

CREATE TABLE IF NOT EXISTS documents_metadata (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  file_path TEXT NOT NULL UNIQUE,
  file_name TEXT NOT NULL,
  file_size BIGINT NOT NULL,
  document_type TEXT NOT NULL,
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  uploaded_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  client_id UUID,
  is_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE documents_metadata ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert their own document metadata"
ON documents_metadata FOR INSERT TO authenticated
WITH CHECK (uploaded_by = auth.uid());

CREATE POLICY "Users can view their own document metadata"
ON documents_metadata FOR SELECT TO authenticated
USING (uploaded_by = auth.uid());

-- ============================================================================
-- DONE! Click "Run" button above
-- ============================================================================

