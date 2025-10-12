-- =====================================================
-- MASTER MIGRATION SCRIPT
-- Run this script to ensure all database schema is up to date
-- =====================================================
-- 
-- ⚠️ CRITICAL: Run in Supabase SQL Editor
-- If you get "user_addresses table not found" error:
-- 1. Run URGENT_CREATE_USER_ADDRESSES.sql first
-- 2. Then run this complete migration script
-- =====================================================

-- This script runs all necessary migrations in the correct order
-- Execute this in your Supabase SQL Editor

\echo 'Starting migration process...'

-- Step 1: Add user addresses system (CRITICAL - Required for orders)
\echo 'Adding user addresses system...'
\i 023_add_user_addresses.sql

-- Step 2: Fix orders RLS policies
\echo 'Fixing orders RLS policies...'
\i 024_fix_orders_rls.sql

-- Step 3: Fix order creation issues (delivery_address_id, payment_method, etc.)
\echo 'Fixing order creation issues...'
\i 026_fix_order_creation_issues.sql

\echo 'All migrations completed successfully!'
\echo 'Please verify the following:'
\echo '1. Check that user_addresses table exists with proper columns'
\echo '2. Check that orders table has all workflow columns'
\echo '3. Verify RLS policies are properly set up'
\echo '4. Test creating an order as a regular user'
\echo '5. Test admin panel order management'

-- Verify critical tables exist
SELECT 'Checking critical tables...' as status;

SELECT 
    table_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = t.table_name) 
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
        ('reviews'),
        ('earnings')
) AS t(table_name);

-- Verify RLS is enabled
SELECT 'Checking RLS status...' as status;

SELECT 
    schemaname,
    tablename,
    CASE WHEN rowsecurity THEN '✓ ENABLED' ELSE '✗ DISABLED' END as rls_status
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('profiles', 'products', 'orders', 'user_addresses', 'order_status_history', 'payment_transactions')
ORDER BY tablename;

-- Verify order workflow columns
SELECT 'Checking orders table columns...' as status;

SELECT 
    column_name,
    data_type,
    CASE WHEN is_nullable = 'YES' THEN 'NULL' ELSE 'NOT NULL' END as nullable
FROM information_schema.columns 
WHERE table_name = 'orders' 
AND table_schema = 'public'
AND column_name IN (
    'payment_method',
    'admin_notes',
    'customer_notes',
    'pickup_address',
    'delivery_address',
    'status_updated_by',
    'status_updated_at',
    'shipping_cost',
    'late_fee',
    'damage_fee',
    'final_amount',
    'refund_amount'
)
ORDER BY column_name;

-- Check for any missing admin users
SELECT 'Checking admin users...' as status;

SELECT 
    COUNT(*) as admin_count,
    CASE 
        WHEN COUNT(*) > 0 THEN '✓ Admin users exist'
        ELSE '⚠ No admin users found - please create at least one admin user'
    END as admin_status
FROM public.profiles 
WHERE is_admin = true;

\echo 'Migration verification complete!'
\echo ''
\echo 'Next steps:'
\echo '1. If any tables are missing, run the base migration scripts first'
\echo '2. If RLS is disabled, enable it with: ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;'
\echo '3. Create at least one admin user to access the admin panel'
\echo '4. Test the complete order workflow using the testing guide'


