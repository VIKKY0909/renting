-- Test storage access after fixing permissions
-- Run this to verify the storage is working correctly

-- 1. Test bucket visibility
SELECT 
  'Bucket visibility test' as test_name,
  COUNT(*) as bucket_count,
  STRING_AGG(id, ', ') as bucket_ids
FROM storage.buckets 
WHERE id IN ('rentimade-images', 'rentimade-avatars');

-- 2. Test bucket details
SELECT 
  'Bucket details' as test_name,
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
FROM storage.buckets 
WHERE id IN ('rentimade-images', 'rentimade-avatars');

-- 3. Test RLS policies
SELECT 
  'RLS Policies' as test_name,
  tablename,
  policyname,
  permissive,
  cmd
FROM pg_policies 
WHERE schemaname = 'storage' 
ORDER BY tablename, policyname;

-- 4. Test if we can access objects (should return empty but no error)
SELECT 
  'Objects access test' as test_name,
  COUNT(*) as object_count
FROM storage.objects 
WHERE bucket_id = 'rentimade-images';

-- 5. Test storage functions availability
SELECT 
  'Storage functions' as test_name,
  routine_name,
  routine_type
FROM information_schema.routines 
WHERE routine_schema = 'storage'
AND routine_name LIKE '%storage%'
ORDER BY routine_name;

-- 6. Final status
SELECT 'Storage access test complete!' as status;
