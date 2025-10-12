-- =====================================================
-- MASTER FIX: Complete Order System Setup
-- Run this ONE script to fix EVERYTHING
-- =====================================================

\echo '========================================='
\echo 'MASTER ORDER SYSTEM FIX'
\echo 'This will fix all order-related issues'
\echo '========================================='

-- =====================================================
-- PART 1: CREATE USER_ADDRESSES TABLE (if missing)
-- =====================================================

\echo ''
\echo 'PART 1: USER ADDRESSES TABLE'
\echo '============================='

-- Check if user_addresses exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'user_addresses'
    ) THEN
        RAISE NOTICE '→ Creating user_addresses table...';
        
        -- Create table
        CREATE TABLE public.user_addresses (
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
        
        -- Create indexes
        CREATE INDEX idx_user_addresses_user_id ON public.user_addresses(user_id);
        CREATE INDEX idx_user_addresses_default ON public.user_addresses(user_id, is_default) WHERE is_default = TRUE;
        
        -- Enable RLS
        ALTER TABLE public.user_addresses ENABLE ROW LEVEL SECURITY;
        
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
        
        RAISE NOTICE '✓ user_addresses table created successfully';
    ELSE
        RAISE NOTICE '✓ user_addresses table already exists';
    END IF;
END $$;

-- Create trigger for updated_at
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

-- Create function to ensure only one default address per user
CREATE OR REPLACE FUNCTION ensure_single_default_address()
RETURNS TRIGGER AS $$
BEGIN
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

DROP TRIGGER IF EXISTS trigger_ensure_single_default_address ON public.user_addresses;
CREATE TRIGGER trigger_ensure_single_default_address
  BEFORE INSERT OR UPDATE ON public.user_addresses
  FOR EACH ROW EXECUTE FUNCTION ensure_single_default_address();

\echo '✓ Part 1 Complete: user_addresses ready'

-- =====================================================
-- PART 2: FIX ORDERS TABLE
-- =====================================================

\echo ''
\echo 'PART 2: FIX ORDERS TABLE'
\echo '========================'

-- Add delivery_address_id column
\echo ''
\echo '→ Adding delivery_address_id column...'

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'orders' 
        AND table_schema = 'public'
        AND column_name = 'delivery_address_id'
    ) THEN
        ALTER TABLE public.orders 
        ADD COLUMN delivery_address_id UUID 
        REFERENCES public.user_addresses(id) ON DELETE SET NULL;
        
        RAISE NOTICE '✓ delivery_address_id column added';
    ELSE
        RAISE NOTICE '✓ delivery_address_id already exists';
    END IF;
END $$;

-- Create index
CREATE INDEX IF NOT EXISTS idx_orders_delivery_address_id 
ON public.orders(delivery_address_id);

\echo '✓ delivery_address_id column ready'

-- Make payment_method nullable
\echo ''
\echo '→ Making payment_method nullable...'

ALTER TABLE public.orders 
ALTER COLUMN payment_method DROP NOT NULL;

\echo '✓ payment_method is now nullable'

-- =====================================================
-- PART 3: FIX RLS POLICIES
-- =====================================================

\echo ''
\echo 'PART 3: FIX RLS POLICIES'
\echo '========================'

-- Drop ALL existing policies
\echo ''
\echo '→ Dropping all existing policies...'

DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can create orders" ON public.orders;
DROP POLICY IF EXISTS "Users and owners can update orders" ON public.orders;
DROP POLICY IF EXISTS "Admins can delete orders" ON public.orders;
DROP POLICY IF EXISTS "Admins can manage all orders" ON public.orders;
DROP POLICY IF EXISTS "orders_select_policy" ON public.orders;
DROP POLICY IF EXISTS "orders_insert_policy" ON public.orders;
DROP POLICY IF EXISTS "orders_update_policy" ON public.orders;
DROP POLICY IF EXISTS "orders_delete_policy" ON public.orders;

\echo '✓ Old policies removed'

-- Create new RLS policies
\echo ''
\echo '→ Creating new RLS policies...'

-- SELECT
CREATE POLICY "orders_select_policy" ON public.orders
FOR SELECT USING (
    auth.uid() = user_id 
    OR 
    auth.uid() = owner_id 
    OR 
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = auth.uid() AND is_admin = true
    )
);

-- INSERT
CREATE POLICY "orders_insert_policy" ON public.orders
FOR INSERT WITH CHECK (
    auth.uid() = user_id
    AND
    auth.uid() != owner_id
);

-- UPDATE
CREATE POLICY "orders_update_policy" ON public.orders
FOR UPDATE USING (
    auth.uid() = user_id 
    OR 
    auth.uid() = owner_id 
    OR 
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = auth.uid() AND is_admin = true
    )
);

-- DELETE
CREATE POLICY "orders_delete_policy" ON public.orders
FOR DELETE USING (
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = auth.uid() AND is_admin = true
    )
);

\echo '✓ New RLS policies created'

-- Enable RLS
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.orders TO authenticated;
GRANT ALL ON public.orders TO service_role;

\echo '✓ RLS enabled and permissions granted'

-- =====================================================
-- PART 4: VERIFICATION
-- =====================================================

\echo ''
\echo 'PART 4: VERIFICATION'
\echo '===================='

-- Verify tables exist
\echo ''
\echo 'Tables Status:'
SELECT 
    t.table_name,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name = t.table_name
        ) 
        THEN '✓ EXISTS'
        ELSE '✗ MISSING'
    END as status
FROM (VALUES ('user_addresses'), ('orders')) AS t(table_name);

-- Verify critical columns
\echo ''
\echo 'Critical Columns in orders:'
SELECT 
    column_name,
    data_type,
    CASE WHEN is_nullable = 'YES' THEN 'NULL' ELSE 'NOT NULL' END as nullable
FROM information_schema.columns 
WHERE table_name = 'orders' 
AND table_schema = 'public'
AND column_name IN (
    'id',
    'user_id',
    'product_id',
    'owner_id',
    'delivery_address_id',
    'payment_method',
    'status',
    'payment_status',
    'total_amount'
)
ORDER BY 
    CASE column_name
        WHEN 'id' THEN 1
        WHEN 'user_id' THEN 2
        WHEN 'product_id' THEN 3
        WHEN 'owner_id' THEN 4
        WHEN 'delivery_address_id' THEN 5
        WHEN 'payment_method' THEN 6
        WHEN 'status' THEN 7
        WHEN 'payment_status' THEN 8
        WHEN 'total_amount' THEN 9
    END;

-- Verify RLS policies
\echo ''
\echo 'RLS Policies on orders:'
SELECT 
    policyname,
    cmd as operation
FROM pg_policies 
WHERE tablename = 'orders' 
AND schemaname = 'public'
ORDER BY cmd, policyname;

-- Verify RLS is enabled
\echo ''
\echo 'RLS Status:'
SELECT 
    tablename,
    CASE WHEN rowsecurity THEN '✓✓✓ ENABLED' ELSE '✗✗✗ DISABLED' END as rls_status
FROM pg_tables 
WHERE tablename IN ('orders', 'user_addresses') 
AND schemaname = 'public'
ORDER BY tablename;

\echo ''
\echo '========================================='
\echo '✓✓✓ MASTER FIX COMPLETE!'
\echo '========================================='
\echo ''
\echo 'WHAT WAS FIXED:'
\echo '1. ✓ user_addresses table created (if needed)'
\echo '2. ✓ delivery_address_id added to orders'
\echo '3. ✓ payment_method made nullable'
\echo '4. ✓ All RLS policies reset and recreated'
\echo '5. ✓ Permissions granted'
\echo '6. ✓ Indexes created'
\echo ''
\echo 'NEXT STEPS:'
\echo '1. Refresh your app (Ctrl+Shift+R)'
\echo '2. Go to Profile → Addresses'
\echo '3. Add at least one address'
\echo '4. Browse products and add to cart'
\echo '5. Go to checkout and select address'
\echo '6. Place order'
\echo '7. Check Profile → My Orders'
\echo '8. Check Admin Panel → Orders (if admin)'
\echo ''
\echo 'Your order system is now fully functional!'
\echo '========================================='


