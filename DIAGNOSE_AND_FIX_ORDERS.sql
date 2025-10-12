-- =====================================================
-- DIAGNOSE AND FIX ORDER ISSUES
-- Run this in Supabase SQL Editor to find and fix the problem
-- =====================================================

\echo '========================================='
\echo 'STEP 1: CHECK IF TABLES EXIST'
\echo '========================================='

-- Check if user_addresses table exists
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name = 'user_addresses'
        ) 
        THEN '✓ user_addresses table EXISTS'
        ELSE '✗ user_addresses table MISSING - RUN 023_add_user_addresses.sql'
    END as user_addresses_status;

\echo ''
\echo '========================================='
\echo 'STEP 2: CHECK ORDERS TABLE COLUMNS'
\echo '========================================='

-- Check if orders table has the required columns
SELECT 
    column_name,
    data_type,
    CASE WHEN is_nullable = 'YES' THEN 'NULL' ELSE 'NOT NULL' END as nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'orders' 
AND table_schema = 'public'
AND column_name IN (
    'delivery_address_id',
    'payment_method',
    'status_updated_by',
    'status_updated_at'
)
ORDER BY column_name;

-- If the above query returns 0 rows, these columns are MISSING

\echo ''
\echo '========================================='
\echo 'STEP 3: CHECK IF ANY ORDERS EXIST'
\echo '========================================='

-- Count total orders in database
SELECT 
    COUNT(*) as total_orders,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_orders,
    COUNT(CASE WHEN status = 'confirmed' THEN 1 END) as confirmed_orders,
    COUNT(CASE WHEN payment_status = 'paid' THEN 1 END) as paid_orders
FROM public.orders;

\echo ''
\echo '========================================='
\echo 'STEP 4: VIEW RECENT ORDERS (Last 5)'
\echo '========================================='

-- View most recent orders
SELECT 
    id,
    user_id,
    product_id,
    status,
    payment_status,
    total_amount,
    created_at
FROM public.orders
ORDER BY created_at DESC
LIMIT 5;

\echo ''
\echo '========================================='
\echo 'STEP 5: CHECK RLS POLICIES'
\echo '========================================='

-- View current RLS policies on orders table
SELECT 
    policyname,
    cmd as operation,
    permissive,
    roles,
    qual as using_expression,
    with_check as with_check_expression
FROM pg_policies 
WHERE tablename = 'orders' 
AND schemaname = 'public'
ORDER BY cmd, policyname;

\echo ''
\echo '========================================='
\echo 'STEP 6: TEST RLS POLICIES'
\echo '========================================='

-- Check if current user can see orders
SELECT 
    'Current user ID: ' || auth.uid()::text as current_user,
    CASE 
        WHEN EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true)
        THEN '✓ User is ADMIN'
        ELSE '○ User is NOT admin'
    END as admin_status;

-- Try to count orders visible to current user
SELECT 
    COUNT(*) as orders_visible_to_me,
    COUNT(CASE WHEN user_id = auth.uid() THEN 1 END) as my_orders,
    COUNT(CASE WHEN owner_id = auth.uid() THEN 1 END) as orders_for_my_products
FROM public.orders;

\echo ''
\echo '========================================='
\echo 'STEP 7: CHECK USER ADDRESSES'
\echo '========================================='

-- Check if current user has any addresses
SELECT 
    COUNT(*) as my_addresses_count,
    COUNT(CASE WHEN is_default = true THEN 1 END) as default_addresses
FROM public.user_addresses
WHERE user_id = auth.uid();

-- Show user's addresses
SELECT 
    id,
    address_type,
    full_name,
    city,
    state,
    is_default,
    created_at
FROM public.user_addresses
WHERE user_id = auth.uid()
ORDER BY is_default DESC, created_at DESC;

\echo ''
\echo '========================================='
\echo 'DIAGNOSTIC SUMMARY'
\echo '========================================='
\echo ''
\echo 'Review the results above to identify the issue:'
\echo ''
\echo '1. If user_addresses table is MISSING:'
\echo '   → Run: scripts/023_add_user_addresses.sql'
\echo ''
\echo '2. If delivery_address_id column is missing from orders:'
\echo '   → Run: scripts/026_fix_order_creation_issues.sql'
\echo ''
\echo '3. If total_orders is 0:'
\echo '   → Order was not saved (probably due to missing columns)'
\echo '   → Fix the schema first, then try placing order again'
\echo ''
\echo '4. If total_orders > 0 but orders_visible_to_me is 0:'
\echo '   → RLS policy issue'
\echo '   → Run: scripts/026_fix_order_creation_issues.sql'
\echo ''
\echo '5. If my_addresses_count is 0:'
\echo '   → Add an address in Profile → Addresses'
\echo '   → Then try placing order again'
\echo ''
\echo '========================================='

-- =====================================================
-- QUICK FIX: If you just want to fix everything now
-- =====================================================

\echo ''
\echo ''
\echo '🚀 QUICK FIX OPTION:'
\echo '==================='
\echo 'To fix all issues at once, run these scripts in order:'
\echo '1. scripts/023_add_user_addresses.sql'
\echo '2. scripts/026_fix_order_creation_issues.sql'
\echo ''
\echo 'Then refresh your app and try placing an order again.'
\echo '========================================='


