-- =====================================================
-- DEBUG ORDERS - Troubleshooting Script
-- Run this to diagnose order visibility issues
-- =====================================================

\echo '========================================='
\echo 'ORDERS DEBUG REPORT'
\echo '========================================='
\echo ''

-- 1. Check if orders table exists and has data
\echo '1. CHECKING ORDERS TABLE...'
SELECT 
    COUNT(*) as total_orders,
    COUNT(*) FILTER (WHERE status = 'pending') as pending,
    COUNT(*) FILTER (WHERE status = 'confirmed') as confirmed,
    COUNT(*) FILTER (WHERE status = 'completed') as completed
FROM public.orders;

\echo ''
\echo '2. RECENT ORDERS (Last 10)...'
SELECT 
    id,
    user_id,
    owner_id,
    product_id,
    status,
    payment_status,
    total_amount,
    created_at
FROM public.orders
ORDER BY created_at DESC
LIMIT 10;

\echo ''
\echo '3. CHECKING RLS POLICIES ON ORDERS...'
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    CASE 
        WHEN qual IS NOT NULL THEN 'Has USING clause'
        ELSE 'No USING clause'
    END as using_clause,
    CASE 
        WHEN with_check IS NOT NULL THEN 'Has WITH CHECK clause'
        ELSE 'No WITH CHECK clause'
    END as with_check_clause
FROM pg_policies 
WHERE tablename = 'orders' 
AND schemaname = 'public'
ORDER BY policyname;

\echo ''
\echo '4. CHECKING ADMIN USERS...'
SELECT 
    id,
    email,
    full_name,
    is_admin,
    created_at
FROM public.profiles
WHERE is_admin = true;

\echo ''
\echo '5. CHECKING ORDER RELATIONSHIPS...'
SELECT 
    o.id as order_id,
    o.status,
    u.email as customer_email,
    u.full_name as customer_name,
    owner.email as owner_email,
    owner.full_name as owner_name,
    p.title as product_title,
    p.status as product_status
FROM public.orders o
LEFT JOIN public.profiles u ON o.user_id = u.id
LEFT JOIN public.profiles owner ON o.owner_id = owner.id
LEFT JOIN public.products p ON o.product_id = p.id
ORDER BY o.created_at DESC
LIMIT 5;

\echo ''
\echo '6. CHECKING FOR ORPHANED ORDERS (missing relationships)...'
SELECT 
    o.id,
    o.status,
    CASE WHEN o.user_id IS NULL THEN '❌ Missing user_id' 
         WHEN NOT EXISTS (SELECT 1 FROM profiles WHERE id = o.user_id) THEN '❌ User not found' 
         ELSE '✓ User OK' END as user_check,
    CASE WHEN o.owner_id IS NULL THEN '❌ Missing owner_id'
         WHEN NOT EXISTS (SELECT 1 FROM profiles WHERE id = o.owner_id) THEN '❌ Owner not found'
         ELSE '✓ Owner OK' END as owner_check,
    CASE WHEN o.product_id IS NULL THEN '❌ Missing product_id'
         WHEN NOT EXISTS (SELECT 1 FROM products WHERE id = o.product_id) THEN '❌ Product not found'
         ELSE '✓ Product OK' END as product_check
FROM public.orders o
ORDER BY o.created_at DESC
LIMIT 10;

\echo ''
\echo '7. CHECKING ORDER STATUS HISTORY...'
SELECT 
    COUNT(*) as total_history_records,
    COUNT(DISTINCT order_id) as orders_with_history
FROM public.order_status_history;

\echo ''
\echo '8. VERIFYING REQUIRED COLUMNS EXIST...'
SELECT 
    column_name,
    data_type,
    CASE WHEN is_nullable = 'YES' THEN 'NULL' ELSE 'NOT NULL' END as nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'orders' 
AND table_schema = 'public'
AND column_name IN (
    'payment_method',
    'status_updated_by',
    'status_updated_at',
    'admin_notes',
    'customer_notes'
)
ORDER BY column_name;

\echo ''
\echo '9. TEST RLS AS ADMIN USER...'
\echo 'Run this query while logged in as admin to test visibility:'
\echo ''
\echo 'SELECT id, status, created_at FROM orders ORDER BY created_at DESC LIMIT 5;'
\echo ''

\echo '========================================='
\echo 'COMMON ISSUES & FIXES'
\echo '========================================='
\echo ''
\echo 'Issue 1: No orders found'
\echo 'Fix: Create test orders using CREATE_TEST_ORDERS.sql'
\echo ''
\echo 'Issue 2: Orders exist but not visible'
\echo 'Fix: Check RLS policies, verify admin user has is_admin = true'
\echo ''
\echo 'Issue 3: Orders missing relationships'
\echo 'Fix: Check section 6 above for orphaned orders'
\echo ''
\echo 'Issue 4: API returns empty array'
\echo 'Fix: Check browser console and server logs for errors'
\echo ''
\echo '========================================='
\echo 'END DEBUG REPORT'
\echo '========================================='


