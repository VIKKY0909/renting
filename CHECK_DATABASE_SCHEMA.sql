-- =====================================================
-- COMPREHENSIVE DATABASE SCHEMA CHECK
-- Run this to see exactly what's in your database right now
-- =====================================================

\echo '========================================='
\echo 'COMPREHENSIVE SCHEMA VERIFICATION'
\echo '========================================='

-- Step 1: Check if tables exist
\echo ''
\echo '1. CHECKING IF TABLES EXIST:'
\echo '----------------------------'

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
FROM (
    VALUES 
        ('profiles'),
        ('categories'),
        ('products'),
        ('orders'),
        ('user_addresses'),
        ('order_status_history'),
        ('payment_transactions'),
        ('reviews')
) AS t(table_name);

-- Step 2: Check ALL columns in orders table
\echo ''
\echo '2. ALL COLUMNS IN ORDERS TABLE:'
\echo '-------------------------------'

SELECT 
    column_name,
    data_type,
    CASE WHEN is_nullable = 'YES' THEN 'NULL' ELSE 'NOT NULL' END as nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'orders' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Step 3: Check for critical missing columns
\echo ''
\echo '3. CRITICAL COLUMNS CHECK:'
\echo '--------------------------'

SELECT 
    c.column_name,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'orders' 
            AND table_schema = 'public'
            AND column_name = c.column_name
        )
        THEN '✓ EXISTS'
        ELSE '✗✗✗ MISSING - THIS IS THE PROBLEM!'
    END as status
FROM (
    VALUES 
        ('delivery_address_id'),
        ('payment_method'),
        ('status_updated_by'),
        ('status_updated_at'),
        ('user_id'),
        ('product_id'),
        ('owner_id'),
        ('total_amount'),
        ('status'),
        ('payment_status')
) AS c(column_name);

-- Step 4: Check if user_addresses table has data
\echo ''
\echo '4. USER ADDRESSES TABLE:'
\echo '------------------------'

SELECT COUNT(*) as total_addresses FROM public.user_addresses;

SELECT 
    id,
    user_id,
    address_type,
    full_name,
    city,
    state,
    is_default
FROM public.user_addresses
LIMIT 5;

-- Step 5: Check if ANY orders exist
\echo ''
\echo '5. ORDERS TABLE DATA:'
\echo '--------------------'

SELECT COUNT(*) as total_orders FROM public.orders;

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

-- Step 6: Check RLS policies on orders
\echo ''
\echo '6. RLS POLICIES ON ORDERS:'
\echo '--------------------------'

SELECT 
    schemaname,
    tablename,
    CASE WHEN rowsecurity THEN '✓ ENABLED' ELSE '✗ DISABLED' END as rls_status
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'orders';

SELECT 
    policyname,
    cmd as operation,
    CASE WHEN permissive = 'PERMISSIVE' THEN '✓' ELSE 'RESTRICTIVE' END as type
FROM pg_policies 
WHERE tablename = 'orders' 
AND schemaname = 'public'
ORDER BY cmd, policyname;

-- Step 7: Test if current user can see orders
\echo ''
\echo '7. CURRENT USER ACCESS TEST:'
\echo '----------------------------'

SELECT 
    'User ID: ' || COALESCE(auth.uid()::text, 'NOT AUTHENTICATED') as current_user;

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND is_admin = true
        )
        THEN '✓ Current user IS an admin'
        ELSE '○ Current user is NOT an admin'
    END as admin_status;

-- Try to count orders with RLS
SELECT 
    COUNT(*) as orders_i_can_see
FROM public.orders;

-- Step 8: Check foreign key constraints
\echo ''
\echo '8. FOREIGN KEY CONSTRAINTS ON ORDERS:'
\echo '-------------------------------------'

SELECT
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'orders'
    AND tc.table_schema = 'public'
ORDER BY tc.constraint_name;

\echo ''
\echo '========================================='
\echo 'DIAGNOSTIC COMPLETE'
\echo '========================================='
\echo ''
\echo 'WHAT TO LOOK FOR:'
\echo ''
\echo '1. If delivery_address_id shows "MISSING":'
\echo '   → The column was NOT added to your database'
\echo '   → Migration script did not run successfully'
\echo ''
\echo '2. If total_orders = 0:'
\echo '   → No orders exist in database'
\echo '   → Previous order attempts failed'
\echo ''
\echo '3. If orders_i_can_see = 0 but total_orders > 0:'
\echo '   → RLS policy is blocking you'
\echo ''
\echo '4. If RLS shows "DISABLED":'
\echo '   → RLS is turned off (security issue)'
\echo ''
\echo '5. If no policies are listed:'
\echo '   → Policies were not created'
\echo ''
\echo '========================================='


