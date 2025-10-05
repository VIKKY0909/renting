-- Fix storage permissions and bucket visibility
-- This script addresses the "Found 0 buckets" issue

-- 1. First, let's check what buckets exist
SELECT id, name, public, created_at FROM storage.buckets ORDER BY created_at;

-- 2. Check current RLS status
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'storage' AND tablename = 'buckets';

-- 3. Check if RLS is enabled on buckets table
SELECT relrowsecurity FROM pg_class WHERE relname = 'buckets' AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'storage');

-- 4. If RLS is enabled on buckets, we need to create a policy to allow reading buckets
-- First, let's disable RLS on buckets table temporarily to allow access
ALTER TABLE storage.buckets DISABLE ROW LEVEL SECURITY;

-- 5. Re-enable RLS but with proper policies
ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

-- 6. Create policy to allow reading buckets (this is what was missing!)
CREATE POLICY "Allow public to read buckets" ON storage.buckets
FOR SELECT USING (true);

-- 7. Create policy to allow authenticated users to read buckets
CREATE POLICY "Allow authenticated users to read buckets" ON storage.buckets
FOR SELECT USING (auth.role() = 'authenticated');

-- 8. Ensure our buckets are public and accessible
UPDATE storage.buckets 
SET public = true 
WHERE id IN ('rentimade-images', 'rentimade-avatars');

-- 9. Fix objects table RLS policies
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 10. Drop existing policies and recreate them properly
DROP POLICY IF EXISTS "Allow public to view product images" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to upload product images" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to update their own product images" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to delete their own product images" ON storage.objects;
DROP POLICY IF EXISTS "Allow public to view avatars" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to upload avatars" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to update their own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to delete their own avatars" ON storage.objects;

-- 11. Create comprehensive policies for objects
CREATE POLICY "Allow public to view all objects" ON storage.objects
FOR SELECT USING (true);

CREATE POLICY "Allow authenticated users to upload to rentimade-images" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'rentimade-images' 
  AND auth.role() = 'authenticated'
);

CREATE POLICY "Allow authenticated users to upload to rentimade-avatars" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'rentimade-avatars' 
  AND auth.role() = 'authenticated'
);

CREATE POLICY "Allow authenticated users to update their objects" ON storage.objects
FOR UPDATE USING (
  auth.role() = 'authenticated' 
  AND bucket_id IN ('rentimade-images', 'rentimade-avatars')
);

CREATE POLICY "Allow authenticated users to delete their objects" ON storage.objects
FOR DELETE USING (
  auth.role() = 'authenticated' 
  AND bucket_id IN ('rentimade-images', 'rentimade-avatars')
);

-- 12. Verify the setup
SELECT 'Storage permissions fixed!' as status;

-- 13. Test bucket visibility
SELECT id, name, public, file_size_limit 
FROM storage.buckets 
WHERE id IN ('rentimade-images', 'rentimade-avatars');

-- 14. Test policies
SELECT policyname, permissive, roles, cmd 
FROM pg_policies 
WHERE schemaname = 'storage' 
ORDER BY tablename, policyname;
