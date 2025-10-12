-- =====================================================
-- URGENT: CREATE USER ADDRESSES TABLE
-- Run this script in Supabase SQL Editor NOW
-- =====================================================

-- Check if table exists
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name = 'user_addresses'
        ) 
        THEN '✓ user_addresses table EXISTS'
        ELSE '✗ user_addresses table MISSING - Creating now...'
    END as status;

-- Create user_addresses table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.user_addresses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  address_type TEXT NOT NULL DEFAULT 'home' CHECK (address_type IN ('home', 'work', 'other')),
  is_default BOOLEAN DEFAULT FALSE,
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  address_line_1 TEXT NOT NULL,
  address_line_2 TEXT,
  city TEXT NOT NULL,
  state TEXT NOT NULL,
  pincode TEXT NOT NULL,
  landmark TEXT,
  instructions TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_addresses_user_id ON public.user_addresses(user_id);
CREATE INDEX IF NOT EXISTS idx_user_addresses_default ON public.user_addresses(user_id, is_default) WHERE is_default = TRUE;

-- Add trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_user_addresses_updated_at ON public.user_addresses;
CREATE TRIGGER update_user_addresses_updated_at 
  BEFORE UPDATE ON public.user_addresses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to ensure only one default address per user
CREATE OR REPLACE FUNCTION ensure_single_default_address()
RETURNS TRIGGER AS $$
BEGIN
  -- If setting a new default address, unset all other default addresses for this user
  IF NEW.is_default = TRUE THEN
    UPDATE public.user_addresses 
    SET is_default = FALSE 
    WHERE user_id = NEW.user_id 
    AND id != NEW.id 
    AND is_default = TRUE;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to ensure single default address
DROP TRIGGER IF EXISTS trigger_ensure_single_default_address ON public.user_addresses;
CREATE TRIGGER trigger_ensure_single_default_address
  BEFORE INSERT OR UPDATE ON public.user_addresses
  FOR EACH ROW EXECUTE FUNCTION ensure_single_default_address();

-- Enable Row Level Security
ALTER TABLE public.user_addresses ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own addresses" ON public.user_addresses;
DROP POLICY IF EXISTS "Users can insert their own addresses" ON public.user_addresses;
DROP POLICY IF EXISTS "Users can update their own addresses" ON public.user_addresses;
DROP POLICY IF EXISTS "Users can delete their own addresses" ON public.user_addresses;

-- Create RLS policies
CREATE POLICY "Users can view their own addresses" ON public.user_addresses
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own addresses" ON public.user_addresses
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own addresses" ON public.user_addresses
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own addresses" ON public.user_addresses
  FOR DELETE USING (auth.uid() = user_id);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_addresses TO authenticated;
GRANT ALL ON public.user_addresses TO service_role;

-- Verify the table was created successfully
SELECT 
    'Table: ' || table_name as info,
    'Columns: ' || COUNT(*)::TEXT as column_count
FROM information_schema.columns 
WHERE table_name = 'user_addresses' 
AND table_schema = 'public'
GROUP BY table_name;

-- Show all columns
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_addresses' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Show RLS policies
SELECT 
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename = 'user_addresses' 
AND schemaname = 'public'
ORDER BY policyname;

-- Final verification
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name = 'user_addresses'
        ) 
        THEN '✓✓✓ SUCCESS! user_addresses table is ready to use'
        ELSE '✗✗✗ ERROR: Table still not created'
    END as final_status;

\echo ''
\echo '========================================='
\echo 'USER ADDRESSES TABLE SETUP COMPLETE'
\echo '========================================='
\echo ''
\echo 'Next steps:'
\echo '1. Go to your application'
\echo '2. Navigate to Profile → Addresses'
\echo '3. Click "Add Address"'
\echo '4. Fill in all required fields'
\echo '5. Save'
\echo ''
\echo 'The address error should now be fixed!'
\echo '========================================='


