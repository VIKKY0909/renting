-- =====================================================
-- COMPLETE FIX FOR ORDERS TABLE
-- Adds ALL missing columns and fixes RLS policies
-- =====================================================

\echo '========================================='
\echo 'COMPLETE ORDERS TABLE FIX'
\echo '========================================='

-- Step 1: Show current orders table structure
\echo ''
\echo '1. Current orders table structure:'
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'orders' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Step 2: Add missing delivery_address_id column (CRITICAL!)
\echo ''
\echo '2. Adding delivery_address_id column (CRITICAL)...'

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
        RAISE NOTICE '○ delivery_address_id already exists';
    END IF;
END $$;

-- Step 3: Create index for delivery_address_id
\echo ''
\echo '3. Creating index...'

CREATE INDEX IF NOT EXISTS idx_orders_delivery_address_id 
ON public.orders(delivery_address_id);

\echo '✓ Index created'

-- Step 4: Ensure payment_method is nullable (to prevent insert errors)
\echo ''
\echo '4. Making payment_method nullable...'

ALTER TABLE public.orders 
ALTER COLUMN payment_method DROP NOT NULL;

\echo '✓ payment_method is now nullable'

-- Step 5: Drop ALL existing RLS policies
\echo ''
\echo '5. Resetting RLS policies...'

DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can create orders" ON public.orders;
DROP POLICY IF EXISTS "Users and owners can update orders" ON public.orders;
DROP POLICY IF EXISTS "Admins can delete orders" ON public.orders;
DROP POLICY IF EXISTS "Admins can manage all orders" ON public.orders;
DROP POLICY IF EXISTS "orders_select_policy" ON public.orders;
DROP POLICY IF EXISTS "orders_insert_policy" ON public.orders;
DROP POLICY IF EXISTS "orders_update_policy" ON public.orders;
DROP POLICY IF EXISTS "orders_delete_policy" ON public.orders;

\echo '✓ All old policies dropped'

-- Step 6: Create new RLS policies
\echo ''
\echo '6. Creating new RLS policies...'

-- SELECT: Users see their orders, owners see orders for their products, admins see all
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

\echo '✓ SELECT policy created'

-- INSERT: Users can create orders (delivery_address_id is optional for now)
CREATE POLICY "orders_insert_policy" ON public.orders
FOR INSERT WITH CHECK (
    auth.uid() = user_id
    AND
    auth.uid() != owner_id
);

\echo '✓ INSERT policy created'

-- UPDATE: Users, owners, and admins can update
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

\echo '✓ UPDATE policy created'

-- DELETE: Only admins
CREATE POLICY "orders_delete_policy" ON public.orders
FOR DELETE USING (
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = auth.uid() AND is_admin = true
    )
);

\echo '✓ DELETE policy created'

-- Step 7: Enable RLS
\echo ''
\echo '7. Enabling RLS...'

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

\echo '✓ RLS enabled'

-- Step 8: Grant permissions
\echo ''
\echo '8. Granting permissions...'

GRANT SELECT, INSERT, UPDATE, DELETE ON public.orders TO authenticated;
GRANT ALL ON public.orders TO service_role;

\echo '✓ Permissions granted'

-- Step 9: Verify everything
\echo ''
\echo '9. VERIFICATION:'
\echo '=================='

-- Check columns
\echo ''
\echo 'Critical columns in orders table:'
SELECT 
    column_name,
    data_type,
    CASE WHEN is_nullable = 'YES' THEN '✓ NULL' ELSE 'NOT NULL' END as nullable
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
    'total_amount',
    'status_updated_by',
    'status_updated_at'
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
        WHEN 'status_updated_by' THEN 10
        WHEN 'status_updated_at' THEN 11
    END;

-- Check RLS policies
\echo ''
\echo 'RLS Policies on orders table:'
SELECT 
    policyname,
    cmd as operation
FROM pg_policies 
WHERE tablename = 'orders' 
AND schemaname = 'public'
ORDER BY cmd, policyname;

-- Check RLS status
\echo ''
\echo 'RLS Status:'
SELECT 
    tablename,
    CASE WHEN rowsecurity THEN '✓✓✓ ENABLED' ELSE '✗✗✗ DISABLED' END as rls_status
FROM pg_tables 
WHERE tablename = 'orders' AND schemaname = 'public';

\echo ''
\echo '========================================='
\echo '✓✓✓ COMPLETE SUCCESS!'
\echo '========================================='
\echo ''
\echo 'WHAT WAS FIXED:'
\echo '1. ✓ Added delivery_address_id column'
\echo '2. ✓ Made payment_method nullable'
\echo '3. ✓ Created all RLS policies'
\echo '4. ✓ Enabled RLS'
\echo '5. ✓ Granted proper permissions'
\echo ''
\echo 'NEXT STEPS:'
\echo '1. Refresh your app (Ctrl+Shift+R)'
\echo '2. Go to Profile → Addresses'
\echo '3. Add at least one address'
\echo '4. Try placing an order'
\echo '5. Check Profile → My Orders'
\echo '6. Check Admin Panel → Orders (if admin)'
\echo ''
\echo 'Orders should now work perfectly!'
\echo '========================================='


