-- Check if storage buckets were created successfully
-- Run this to verify the storage setup

-- 1. Check if buckets exist
SELECT id, name, public, file_size_limit, allowed_mime_types, created_at
FROM storage.buckets 
WHERE id IN ('rentimade-images', 'rentimade-avatars')
ORDER BY created_at;

-- 2. Check storage policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
ORDER BY policyname;

-- 3. Check if we can access storage functions
SELECT routine_name, routine_type
FROM information_schema.routines 
WHERE routine_schema = 'storage'
AND routine_name LIKE '%storage%'
ORDER BY routine_name;

-- 4. Test bucket creation if they don't exist
DO $$
BEGIN
    -- Check if rentimade-images bucket exists
    IF NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'rentimade-images') THEN
        INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
        VALUES (
            'rentimade-images',
            'rentimade-images', 
            true,
            5242880, -- 5MB limit
            ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
        );
        RAISE NOTICE 'Created rentimade-images bucket';
    ELSE
        RAISE NOTICE 'rentimade-images bucket already exists';
    END IF;

    -- Check if rentimade-avatars bucket exists
    IF NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'rentimade-avatars') THEN
        INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
        VALUES (
            'rentimade-avatars',
            'rentimade-avatars', 
            true,
            2097152, -- 2MB limit
            ARRAY['image/jpeg', 'image/png', 'image/webp']
        );
        RAISE NOTICE 'Created rentimade-avatars bucket';
    ELSE
        RAISE NOTICE 'rentimade-avatars bucket already exists';
    END IF;
END $$;

-- 5. Create storage policies if they don't exist
DO $$
BEGIN
    -- Drop existing policies if they exist
    DROP POLICY IF EXISTS "Allow authenticated users to upload product images" ON storage.objects;
    DROP POLICY IF EXISTS "Allow public to view product images" ON storage.objects;
    DROP POLICY IF EXISTS "Allow users to update their own product images" ON storage.objects;
    DROP POLICY IF EXISTS "Allow users to delete their own product images" ON storage.objects;
    DROP POLICY IF EXISTS "Allow authenticated users to upload avatars" ON storage.objects;
    DROP POLICY IF EXISTS "Allow public to view avatars" ON storage.objects;
    DROP POLICY IF EXISTS "Allow users to update their own avatars" ON storage.objects;
    DROP POLICY IF EXISTS "Allow users to delete their own avatars" ON storage.objects;

    -- Create new policies
    CREATE POLICY "Allow authenticated users to upload product images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'rentimade-images' 
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = 'product_images'
    );

    CREATE POLICY "Allow public to view product images" ON storage.objects
    FOR SELECT USING (bucket_id = 'rentimade-images');

    CREATE POLICY "Allow users to update their own product images" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'rentimade-images' 
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = 'product_images'
    );

    CREATE POLICY "Allow users to delete their own product images" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'rentimade-images' 
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = 'product_images'
    );

    CREATE POLICY "Allow authenticated users to upload avatars" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'rentimade-avatars' 
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = 'avatars'
    );

    CREATE POLICY "Allow public to view avatars" ON storage.objects
    FOR SELECT USING (bucket_id = 'rentimade-avatars');

    CREATE POLICY "Allow users to update their own avatars" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'rentimade-avatars' 
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = 'avatars'
    );

    CREATE POLICY "Allow users to delete their own avatars" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'rentimade-avatars' 
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = 'avatars'
    );

    RAISE NOTICE 'Storage policies created successfully';
END $$;

-- 6. Final verification
SELECT 'Storage setup complete!' as status;
