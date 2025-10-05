-- =====================================================
-- DISABLE EMAIL VERIFICATION SCRIPT
-- This script removes email verification requirements
-- =====================================================

-- 1. Update auth.users to mark all users as confirmed
-- =====================================================
-- This ensures existing users don't need email verification

UPDATE auth.users 
SET email_confirmed_at = COALESCE(email_confirmed_at, NOW())
WHERE email_confirmed_at IS NULL;

-- 2. Create a function to auto-confirm new users
-- =====================================================
-- This function automatically confirms users when they sign up

CREATE OR REPLACE FUNCTION public.handle_new_user_confirmation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Auto-confirm the user
  UPDATE auth.users 
  SET email_confirmed_at = NOW()
  WHERE id = NEW.id AND email_confirmed_at IS NULL;
  
  RETURN NEW;
END;
$$;

-- 3. Create trigger to auto-confirm users
-- =====================================================
-- This trigger runs when a new user is created

DROP TRIGGER IF EXISTS on_auth_user_created_confirm ON auth.users;
CREATE TRIGGER on_auth_user_created_confirm
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user_confirmation();

-- 4. Update the existing profile creation trigger
-- =====================================================
-- Ensure profile is created even if user is not confirmed

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Auto-confirm the user first
  UPDATE auth.users 
  SET email_confirmed_at = NOW()
  WHERE id = NEW.id AND email_confirmed_at IS NULL;

  -- Insert or update profile with all available metadata
  INSERT INTO public.profiles (
    id, 
    email, 
    full_name, 
    phone, 
    city, 
    state, 
    pincode, 
    avatar_url
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', SPLIT_PART(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'phone', NULL),
    COALESCE(NEW.raw_user_meta_data->>'city', NULL),
    COALESCE(NEW.raw_user_meta_data->>'state', NULL),
    COALESCE(NEW.raw_user_meta_data->>'pincode', NULL),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', NULL)
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = COALESCE(EXCLUDED.full_name, profiles.full_name),
    phone = COALESCE(EXCLUDED.phone, profiles.phone),
    city = COALESCE(EXCLUDED.city, profiles.city),
    state = COALESCE(EXCLUDED.state, profiles.state),
    pincode = COALESCE(EXCLUDED.pincode, profiles.pincode),
    avatar_url = COALESCE(EXCLUDED.avatar_url, profiles.avatar_url),
    updated_at = NOW();
  RETURN NEW;
END;
$$;

-- 5. Grant necessary permissions
-- =====================================================
GRANT EXECUTE ON FUNCTION public.handle_new_user_confirmation() TO anon, authenticated;

-- 6. Test the changes
-- =====================================================
-- Check how many users are confirmed
SELECT 
    'Total users: ' || COUNT(*) as total_users,
    'Confirmed users: ' || COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END) as confirmed_users,
    'Unconfirmed users: ' || COUNT(CASE WHEN email_confirmed_at IS NULL THEN 1 END) as unconfirmed_users
FROM auth.users;

-- 7. Success message
-- =====================================================
SELECT '✅ Email verification disabled successfully!

Changes made:
- All existing users marked as confirmed
- New users will be auto-confirmed
- Profile creation works without email verification
- Users can sign in immediately after registration

To complete the setup:
1. Go to Supabase Dashboard → Authentication → Settings
2. Disable "Enable email confirmations"
3. Save changes

Your users can now sign up and sign in immediately!' as result;
