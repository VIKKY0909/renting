-- =====================================================
-- RESET ALL ORDERS TABLE POLICIES
-- Run this first to clean up existing policies
-- =====================================================

\echo '========================================='
\echo 'RESETTING ALL ORDERS TABLE POLICIES'
\echo '========================================='

-- Step 1: Show current policies
\echo ''
\echo '1. Current policies on orders table:'
SELECT policyname, cmd FROM pg_policies 
WHERE tablename = 'orders' AND schemaname = 'public'
ORDER BY cmd, policyname;

-- Step 2: Drop ALL existing policies (old and new naming conventions)
\echo ''
\echo '2. Dropping all existing policies...'

-- Drop old naming convention
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can create orders" ON public.orders;
DROP POLICY IF EXISTS "Users and owners can update orders" ON public.orders;
DROP POLICY IF EXISTS "Admins can delete orders" ON public.orders;
DROP POLICY IF EXISTS "Admins can manage all orders" ON public.orders;

-- Drop new naming convention
DROP POLICY IF EXISTS "orders_select_policy" ON public.orders;
DROP POLICY IF EXISTS "orders_insert_policy" ON public.orders;
DROP POLICY IF EXISTS "orders_update_policy" ON public.orders;
DROP POLICY IF EXISTS "orders_delete_policy" ON public.orders;

-- Drop any other possible variations
DROP POLICY IF EXISTS "Enable read access for users" ON public.orders;
DROP POLICY IF EXISTS "Enable insert for users" ON public.orders;
DROP POLICY IF EXISTS "Enable update for users and owners" ON public.orders;
DROP POLICY IF EXISTS "Enable delete for admins" ON public.orders;

\echo ''
\echo '3. All policies dropped successfully!'

-- Step 3: Verify policies are gone
\echo ''
\echo '4. Remaining policies (should be empty):'
SELECT policyname, cmd FROM pg_policies 
WHERE tablename = 'orders' AND schemaname = 'public'
ORDER BY cmd, policyname;

\echo ''
\echo '========================================='
\echo 'SUCCESS! All policies removed.'
\echo '========================================='
\echo ''
\echo 'Next step: Run scripts/026_fix_order_creation_issues.sql'
\echo '========================================='


