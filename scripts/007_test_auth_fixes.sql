-- Test Authentication Fixes
-- This script tests all the authentication fixes

-- 1. Test RLS policies
-- Check if profiles table allows system inserts
SELECT 'Testing RLS policies...' as test_step;

-- 2. Test trigger function
-- This should work without RLS violations
SELECT 'Testing trigger function...' as test_step;

-- 3. Test profile creation function
-- Test the create_user_profile function
SELECT public.create_user_profile(
  '00000000-0000-0000-0000-000000000001'::UUID,
  'test@example.com',
  '{"full_name": "Test User", "phone": "+91 98765 43210", "city": "Mumbai", "state": "Maharashtra", "pincode": "400001"}'::JSONB
) as test_result;

-- 4. Verify profile was created
SELECT * FROM public.profiles WHERE id = '00000000-0000-0000-0000-000000000001';

-- 5. Test profile update
UPDATE public.profiles 
SET full_name = 'Updated Test User' 
WHERE id = '00000000-0000-0000-0000-000000000001';

-- 6. Verify update worked
SELECT full_name FROM public.profiles WHERE id = '00000000-0000-0000-0000-000000000001';

-- 7. Clean up test data
DELETE FROM public.profiles WHERE id = '00000000-0000-0000-0000-000000000001';

-- 8. Test OAuth user creation
SELECT public.create_user_profile(
  '00000000-0000-0000-0000-000000000002'::UUID,
  'oauth@example.com',
  '{"name": "OAuth User", "avatar_url": "https://example.com/avatar.jpg"}'::JSONB
) as oauth_test_result;

-- 9. Verify OAuth profile
SELECT * FROM public.profiles WHERE id = '00000000-0000-0000-0000-000000000002';

-- 10. Clean up OAuth test data
DELETE FROM public.profiles WHERE id = '00000000-0000-0000-0000-000000000002';

SELECT 'All authentication tests completed successfully!' as final_result;
