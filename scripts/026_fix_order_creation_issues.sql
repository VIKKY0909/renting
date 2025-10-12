-- =====================================================
-- FIX ORDER CREATION ISSUES
-- This script fixes RLS policies and ensures order creation works
-- =====================================================

\echo '========================================='
\echo 'FIXING ORDER CREATION ISSUES'
\echo '========================================='

-- Step 1: Check current RLS policies
\echo ''
\echo '1. Current RLS Policies on Orders Table:'
SELECT policyname, cmd FROM pg_policies 
WHERE tablename = 'orders' AND schemaname = 'public'
ORDER BY cmd, policyname;

-- Step 2: Drop ALL existing policies to start fresh
\echo ''
\echo '2. Dropping existing policies...'

-- Drop old naming convention
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can create orders" ON public.orders;
DROP POLICY IF EXISTS "Users and owners can update orders" ON public.orders;
DROP POLICY IF EXISTS "Admins can delete orders" ON public.orders;
DROP POLICY IF EXISTS "Admins can manage all orders" ON public.orders;

-- Drop new naming convention (in case script was run before)
DROP POLICY IF EXISTS "orders_select_policy" ON public.orders;
DROP POLICY IF EXISTS "orders_insert_policy" ON public.orders;
DROP POLICY IF EXISTS "orders_update_policy" ON public.orders;
DROP POLICY IF EXISTS "orders_delete_policy" ON public.orders;


-- Step 3: Recreate policies with proper logic
\echo ''
\echo '3. Creating new RLS policies...'

-- SELECT Policy: Users can view their orders, owners can view orders for their products, admins can view all
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

-- INSERT Policy: Users can create orders for themselves (not their own products)
CREATE POLICY "orders_insert_policy" ON public.orders
FOR INSERT WITH CHECK (
    auth.uid() = user_id
    AND
    auth.uid() != owner_id
);

-- UPDATE Policy: Users, owners, and admins can update
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

-- DELETE Policy: Only admins can delete
CREATE POLICY "orders_delete_policy" ON public.orders
FOR DELETE USING (
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = auth.uid() AND is_admin = true
    )
);

-- Step 4: Ensure RLS is enabled
\echo ''
\echo '4. Ensuring RLS is enabled...'
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- Step 5: Grant proper permissions
\echo ''
\echo '5. Granting permissions...'
GRANT SELECT, INSERT, UPDATE, DELETE ON public.orders TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.orders TO anon;
GRANT ALL ON public.orders TO service_role;

-- Step 6: Verify policies were created
\echo ''
\echo '6. Verifying new policies:'
SELECT 
    policyname,
    cmd,
    CASE WHEN roles = '{public}' THEN 'PUBLIC' ELSE array_to_string(roles, ', ') END as applies_to
FROM pg_policies 
WHERE tablename = 'orders' AND schemaname = 'public'
ORDER BY cmd, policyname;

-- Step 7: Check for missing columns that might cause issues
\echo ''
\echo '7. Checking for required columns:'
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'orders' 
AND table_schema = 'public'
AND column_name IN (
    'id', 'user_id', 'product_id', 'owner_id',
    'rental_start_date', 'rental_end_date', 'rental_days',
    'rental_price', 'security_deposit', 'total_amount',
    'status', 'payment_status', 'payment_method'
)
ORDER BY ordinal_position;

-- Step 8: Make payment_method nullable since it might be causing issues
\echo ''
\echo '8. Making payment_method nullable to prevent insertion errors:'
ALTER TABLE public.orders 
ALTER COLUMN payment_method DROP NOT NULL;

ALTER TABLE public.orders 
ALTER COLUMN payment_method SET DEFAULT 'card';

-- Step 9: Test order insertion with a simple test (optional - uncomment to use)
\echo ''
\echo '9. To test order creation, run this after getting proper UUIDs:'
\echo ''
\echo 'INSERT INTO orders ('
\echo '  user_id, product_id, owner_id,'
\echo '  rental_start_date, rental_end_date, rental_days,'
\echo '  rental_price, security_deposit, total_amount,'
\echo '  status, payment_status'
\echo ') VALUES ('
\echo '  ''USER-UUID''::uuid,'
\echo '  ''PRODUCT-UUID''::uuid,'
\echo '  ''OWNER-UUID''::uuid,'
\echo '  CURRENT_DATE + 2,'
\echo '  CURRENT_DATE + 5,'
\echo '  3,'
\echo '  3000.00,'
\echo '  2000.00,'
\echo '  5000.00,'
\echo '  ''pending'','
\echo '  ''pending'''
\echo ');'

-- Step 10: Create a helper function to test RLS
\echo ''
\echo '10. Creating RLS test function...'
CREATE OR REPLACE FUNCTION test_order_rls()
RETURNS TABLE (
    test_name TEXT,
    result TEXT,
    details TEXT
) AS $$
BEGIN
    -- Test 1: Check if RLS is enabled
    RETURN QUERY
    SELECT 
        'RLS Enabled'::TEXT,
        CASE WHEN pg_tables.rowsecurity THEN 'PASS' ELSE 'FAIL' END::TEXT,
        'RLS is ' || CASE WHEN pg_tables.rowsecurity THEN 'enabled' ELSE 'disabled' END::TEXT
    FROM pg_tables
    WHERE schemaname = 'public' AND tablename = 'orders';
    
    -- Test 2: Check policy count
    RETURN QUERY
    SELECT 
        'Policy Count'::TEXT,
        CASE WHEN COUNT(*) >= 4 THEN 'PASS' ELSE 'FAIL' END::TEXT,
        'Found ' || COUNT(*)::TEXT || ' policies (expected 4+)'::TEXT
    FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'orders';
    
    -- Test 3: Check required columns exist
    RETURN QUERY
    SELECT 
        'Required Columns'::TEXT,
        CASE WHEN COUNT(*) >= 13 THEN 'PASS' ELSE 'FAIL' END::TEXT,
        'Found ' || COUNT(*)::TEXT || ' required columns'::TEXT
    FROM information_schema.columns
    WHERE table_schema = 'public' 
    AND table_name = 'orders'
    AND column_name IN (
        'id', 'user_id', 'product_id', 'owner_id',
        'rental_start_date', 'rental_end_date', 'rental_days',
        'rental_price', 'security_deposit', 'total_amount',
        'status', 'payment_status', 'payment_method'
    );
    
    -- Test 4: Check if authenticated role has permissions
    RETURN QUERY
    SELECT 
        'Permissions'::TEXT,
        'CHECK'::TEXT,
        'Verify authenticated role has INSERT, SELECT, UPDATE permissions'::TEXT;
END;
$$ LANGUAGE plpgsql;

-- Run the test
\echo ''
\echo '11. Running RLS tests:'
SELECT * FROM test_order_rls();

\echo ''
\echo '========================================='
\echo 'TROUBLESHOOTING STEPS'
\echo '========================================='
\echo ''
\echo 'If orders still don''t save:'
\echo ''
\echo '1. Check if user has an address:'
\echo '   SELECT COUNT(*) FROM user_addresses WHERE user_id = ''YOUR-USER-UUID'';'
\echo ''
\echo '2. Verify you''re not trying to rent your own product:'
\echo '   SELECT owner_id FROM products WHERE id = ''PRODUCT-UUID'';'
\echo '   -- Should be different from your user_id'
\echo ''
\echo '3. Check browser console for JavaScript errors'
\echo ''
\echo '4. Check if product is available:'
\echo '   SELECT is_available, status FROM products WHERE id = ''PRODUCT-UUID'';'
\echo ''
\echo '5. Try creating order directly in SQL to isolate the issue:'
\echo '   -- Get user, product, and owner UUIDs first'
\echo '   -- Then use the INSERT statement shown above'
\echo ''
\echo '========================================='
\echo 'FIX COMPLETE'
\echo '========================================='

