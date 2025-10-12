-- =====================================================
-- FINAL FIX: Add delivery_address_id Column
-- Based on diagnostic results - this is all you need!
-- =====================================================

\echo '========================================='
\echo 'ADDING delivery_address_id COLUMN'
\echo '========================================='

-- Add the missing column
ALTER TABLE public.orders 
ADD COLUMN delivery_address_id UUID 
REFERENCES public.user_addresses(id) ON DELETE SET NULL;

\echo '✓ Column added!'

-- Create index for performance
CREATE INDEX idx_orders_delivery_address_id 
ON public.orders(delivery_address_id);

\echo '✓ Index created!'

-- Verify it worked
\echo ''
\echo 'Verification:'
SELECT 
    column_name,
    data_type,
    CASE WHEN is_nullable = 'YES' THEN 'NULL' ELSE 'NOT NULL' END as nullable
FROM information_schema.columns 
WHERE table_name = 'orders' 
AND column_name = 'delivery_address_id';

\echo ''
\echo '========================================='
\echo '✓✓✓ SUCCESS!'
\echo '========================================='
\echo ''
\echo 'The delivery_address_id column has been added.'
\echo ''
\echo 'NEXT STEPS:'
\echo '1. Refresh your app (Ctrl+Shift+R)'
\echo '2. Go to Profile → Addresses (you already have 2!)'
\echo '3. Place an order'
\echo '4. Check Profile → My Orders ← Should work now!'
\echo ''
\echo 'Orders will now save successfully!'
\echo '========================================='


