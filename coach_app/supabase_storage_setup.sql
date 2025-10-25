-- ============================================================================
-- SUPABASE STORAGE SETUP - Copy and run in Supabase SQL Editor
-- ============================================================================

-- Step 1: Create Storage Buckets (Run these in Supabase Dashboard → Storage)
-- NOTE: You must create buckets through the dashboard UI, not SQL
-- 1. Create bucket named: avatars (public: ON)
-- 2. Create bucket named: documents (public: OFF)

-- Step 2: Set up RLS Policies for avatars bucket
-- ============================================================================

-- Policy 1: Allow authenticated users to upload avatars
CREATE POLICY "Authenticated users can upload avatars"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'avatars');

-- Policy 2: Allow anyone to view avatars (public bucket)
CREATE POLICY "Anyone can view avatars"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'avatars');

-- Policy 3: Allow users to update avatars
CREATE POLICY "Users can update avatars"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'avatars');

-- Policy 4: Allow users to delete avatars
CREATE POLICY "Users can delete avatars"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'avatars');

-- Step 3: Set up RLS Policies for documents bucket
-- ============================================================================

-- Policy 1: Allow authenticated users to upload documents
CREATE POLICY "Authenticated users can upload documents"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'documents');

-- Policy 2: Only authenticated users can view documents
CREATE POLICY "Authenticated users can view documents"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'documents');

-- Policy 3: Allow users to update documents
CREATE POLICY "Users can update documents"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'documents');

-- Policy 4: Allow users to delete documents
CREATE POLICY "Users can delete documents"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'documents');

-- Step 4: (Optional) Create metadata tracking table
-- ============================================================================

CREATE TABLE IF NOT EXISTS documents_metadata (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  file_path TEXT NOT NULL UNIQUE,
  file_name TEXT NOT NULL,
  file_size BIGINT NOT NULL,
  document_type TEXT NOT NULL,
  content_type TEXT,
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  uploaded_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  client_id UUID,
  is_verified BOOLEAN DEFAULT false,
  verified_by UUID REFERENCES auth.users(id),
  verified_at TIMESTAMP WITH TIME ZONE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on metadata table
ALTER TABLE documents_metadata ENABLE ROW LEVEL SECURITY;

-- RLS Policies for documents_metadata
CREATE POLICY "Users can insert their own document metadata"
ON documents_metadata
FOR INSERT
TO authenticated
WITH CHECK (uploaded_by = auth.uid());

CREATE POLICY "Users can view their own document metadata"
ON documents_metadata
FOR SELECT
TO authenticated
USING (uploaded_by = auth.uid() OR client_id IN (
  SELECT id FROM users WHERE id = auth.uid()
));

CREATE POLICY "Users can update their own document metadata"
ON documents_metadata
FOR UPDATE
TO authenticated
USING (uploaded_by = auth.uid());

CREATE POLICY "Users can delete their own document metadata"
ON documents_metadata
FOR DELETE
TO authenticated
USING (uploaded_by = auth.uid());

-- Create indexes for performance
CREATE INDEX idx_documents_metadata_uploaded_by ON documents_metadata(uploaded_by);
CREATE INDEX idx_documents_metadata_client_id ON documents_metadata(client_id);
CREATE INDEX idx_documents_metadata_document_type ON documents_metadata(document_type);
CREATE INDEX idx_documents_metadata_uploaded_at ON documents_metadata(uploaded_at DESC);

-- Step 5: (Optional) Create function to cleanup old files
-- ============================================================================

CREATE OR REPLACE FUNCTION cleanup_orphaned_files()
RETURNS void AS $$
BEGIN
  -- This is a placeholder for cleanup logic
  -- You can schedule this to run periodically
  RAISE NOTICE 'Cleanup function ready - implement your logic here';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check if policies are created
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'objects' 
  AND (qual LIKE '%avatars%' OR qual LIKE '%documents%' OR with_check LIKE '%avatars%' OR with_check LIKE '%documents%')
ORDER BY policyname;

-- Check if metadata table exists
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'documents_metadata'
ORDER BY ordinal_position;

-- ============================================================================
-- SETUP COMPLETE! 
-- ============================================================================

-- Next steps:
-- 1. Run this SQL in Supabase SQL Editor
-- 2. Create the storage buckets in the UI (avatars, documents)
-- 3. Update your app config with Supabase URL and keys
-- 4. Run: flutter pub get
-- 5. Test uploads in your app!

