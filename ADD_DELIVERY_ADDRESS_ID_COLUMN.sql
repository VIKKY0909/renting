-- =====================================================
-- ADD MISSING delivery_address_id COLUMN TO ORDERS
-- This is the critical missing piece!
-- =====================================================

\echo '========================================='
\echo 'ADDING delivery_address_id TO ORDERS TABLE'
\echo '========================================='

-- Step 1: Check current state
\echo ''
\echo '1. Checking if column already exists...'

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'orders' 
            AND table_schema = 'public'
            AND column_name = 'delivery_address_id'
        )
        THEN '✓ Column already exists - skipping'
        ELSE '✗ Column MISSING - will add now'
    END as delivery_address_id_status;

-- Step 2: Add the column
\echo ''
\echo '2. Adding delivery_address_id column...'

ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS delivery_address_id UUID 
REFERENCES public.user_addresses(id) ON DELETE SET NULL;

\echo '✓ Column added successfully!'

-- Step 3: Create index for performance
\echo ''
\echo '3. Creating index for better performance...'

CREATE INDEX IF NOT EXISTS idx_orders_delivery_address_id 
ON public.orders(delivery_address_id);

\echo '✓ Index created!'

-- Step 4: Verify it was added
\echo ''
\echo '4. Verifying column exists now...'

SELECT 
    column_name,
    data_type,
    CASE WHEN is_nullable = 'YES' THEN 'NULL' ELSE 'NOT NULL' END as nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'orders' 
AND table_schema = 'public'
AND column_name = 'delivery_address_id';

-- Step 5: Show updated orders table structure
\echo ''
\echo '5. Updated orders table columns:'

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
    'delivery_address_id',
    'status',
    'payment_status',
    'payment_method',
    'total_amount'
)
ORDER BY 
    CASE column_name
        WHEN 'id' THEN 1
        WHEN 'user_id' THEN 2
        WHEN 'product_id' THEN 3
        WHEN 'delivery_address_id' THEN 4
        WHEN 'status' THEN 5
        WHEN 'payment_status' THEN 6
        WHEN 'payment_method' THEN 7
        WHEN 'total_amount' THEN 8
    END;

\echo ''
\echo '========================================='
\echo '✓✓✓ SUCCESS!'
\echo '========================================='
\echo ''
\echo 'The delivery_address_id column has been added!'
\echo ''
\echo 'NEXT STEPS:'
\echo '1. Refresh your application (Ctrl+Shift+R)'
\echo '2. Make sure you have an address: Profile → Addresses'
\echo '3. Try placing an order again'
\echo '4. Check Profile → My Orders'
\echo ''
\echo 'Orders should now save successfully!'
\echo '========================================='


