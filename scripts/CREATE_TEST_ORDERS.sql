-- =====================================================
-- CREATE TEST ORDERS
-- This script creates sample orders for testing
-- =====================================================

-- IMPORTANT: Customize these UUIDs before running!
-- Replace with actual UUIDs from your database

-- Step 1: Get your user IDs
\echo 'Step 1: Finding users in your database...'
SELECT 
    id,
    email,
    full_name,
    is_admin
FROM public.profiles
ORDER BY created_at DESC
LIMIT 10;

\echo ''
\echo 'Step 2: Finding products in your database...'
SELECT 
    id,
    title,
    owner_id,
    rental_price,
    security_deposit,
    status,
    is_available
FROM public.products
WHERE status = 'approved' AND is_available = true
ORDER BY created_at DESC
LIMIT 10;

-- Pause here to get the UUIDs you need
\echo ''
\echo '========================================='
\echo 'INSTRUCTIONS:'
\echo '1. Copy a customer user_id from above (not an admin)'
\echo '2. Copy a product owner_id from above (different from customer)'
\echo '3. Copy a product_id from above'
\echo '4. Update the variables below'
\echo '5. Run the INSERT commands'
\echo '========================================='
\echo ''

-- =====================================================
-- CUSTOMIZE THESE VALUES
-- =====================================================
-- Replace these with actual UUIDs from your database:

-- Example usage (UNCOMMENT and UPDATE these lines):
/*
DO $$
DECLARE
    customer_id UUID := 'PASTE-CUSTOMER-USER-ID-HERE';
    owner_id UUID := 'PASTE-OWNER-USER-ID-HERE';
    product_id UUID := 'PASTE-PRODUCT-ID-HERE';
    test_order_id UUID;
BEGIN
    -- Get product details
    DECLARE
        product_rental_price DECIMAL(10,2);
        product_security_deposit DECIMAL(10,2);
    BEGIN
        SELECT rental_price, security_deposit 
        INTO product_rental_price, product_security_deposit
        FROM products 
        WHERE id = product_id;
        
        -- Create test order
        INSERT INTO public.orders (
            user_id,
            product_id,
            owner_id,
            rental_start_date,
            rental_end_date,
            rental_days,
            rental_price,
            security_deposit,
            discount,
            total_amount,
            selected_size,
            status,
            payment_status,
            payment_method,
            created_at
        ) VALUES (
            customer_id,
            product_id,
            owner_id,
            CURRENT_DATE + INTERVAL '2 days',
            CURRENT_DATE + INTERVAL '5 days',
            3,
            product_rental_price * 3,
            product_security_deposit,
            0,
            (product_rental_price * 3) + product_security_deposit,
            'M',
            'pending',
            'pending',
            'card',
            NOW()
        )
        RETURNING id INTO test_order_id;
        
        RAISE NOTICE 'Test order created with ID: %', test_order_id;
        
        -- Update product availability
        UPDATE products 
        SET is_available = false,
            availability_status = 'rented'
        WHERE id = product_id;
        
        RAISE NOTICE 'Product marked as rented';
    END;
END $$;
*/

\echo ''
\echo '========================================='
\echo 'QUICK TEST ORDER CREATION'
\echo '========================================='
\echo ''
\echo 'Option 1: Manual Quick Create'
\echo 'Run this after replacing the UUIDs:'
\echo ''
\echo 'INSERT INTO public.orders ('
\echo '  user_id, product_id, owner_id,'
\echo '  rental_start_date, rental_end_date, rental_days,'
\echo '  rental_price, security_deposit, discount, total_amount,'
\echo '  selected_size, status, payment_status, payment_method'
\echo ') VALUES ('
\echo '  ''CUSTOMER-UUID''::uuid,'
\echo '  ''PRODUCT-UUID''::uuid,'
\echo '  ''OWNER-UUID''::uuid,'
\echo '  CURRENT_DATE + 2,'
\echo '  CURRENT_DATE + 5,'
\echo '  3,'
\echo '  3000.00,'
\echo '  2000.00,'
\echo '  0,'
\echo '  5000.00,'
\echo '  ''M'','
\echo '  ''pending'','
\echo '  ''pending'','
\echo '  ''card'''
\echo ');'
\echo ''

-- Create multiple test orders with different statuses
\echo 'Option 2: Create orders with different statuses (update UUIDs first):'
/*
DO $$
DECLARE
    customer_id UUID := 'PASTE-CUSTOMER-USER-ID-HERE';
    owner_id UUID := 'PASTE-OWNER-USER-ID-HERE';
    product_id UUID := 'PASTE-PRODUCT-ID-HERE';
BEGIN
    -- Pending order
    INSERT INTO orders (user_id, product_id, owner_id, rental_start_date, rental_end_date, 
                        rental_days, rental_price, security_deposit, total_amount, 
                        status, payment_status, payment_method)
    VALUES (customer_id, product_id, owner_id, CURRENT_DATE + 2, CURRENT_DATE + 5, 
            3, 3000, 2000, 5000, 'pending', 'pending', 'card');
    
    -- Confirmed order
    INSERT INTO orders (user_id, product_id, owner_id, rental_start_date, rental_end_date, 
                        rental_days, rental_price, security_deposit, total_amount, 
                        status, payment_status, payment_method)
    VALUES (customer_id, product_id, owner_id, CURRENT_DATE + 3, CURRENT_DATE + 6, 
            3, 3000, 2000, 5000, 'confirmed', 'paid', 'upi');
    
    -- Delivered order
    INSERT INTO orders (user_id, product_id, owner_id, rental_start_date, rental_end_date, 
                        rental_days, rental_price, security_deposit, total_amount, 
                        status, payment_status, payment_method)
    VALUES (customer_id, product_id, owner_id, CURRENT_DATE - 2, CURRENT_DATE + 1, 
            3, 3000, 2000, 5000, 'delivered', 'paid', 'card');
    
    -- Completed order
    INSERT INTO orders (user_id, product_id, owner_id, rental_start_date, rental_end_date, 
                        rental_days, rental_price, security_deposit, total_amount, 
                        status, payment_status, payment_method)
    VALUES (customer_id, product_id, owner_id, CURRENT_DATE - 10, CURRENT_DATE - 7, 
            3, 3000, 2000, 5000, 'completed', 'paid', 'netbanking');
    
    RAISE NOTICE 'Created 4 test orders with different statuses';
END $$;
*/

-- Verify orders were created
\echo ''
\echo 'Verify orders were created:'
\echo ''
SELECT 
    id,
    status,
    payment_status,
    total_amount,
    created_at
FROM public.orders
ORDER BY created_at DESC
LIMIT 10;

\echo ''
\echo '========================================='
\echo 'CLEANUP (if needed)'
\echo '========================================='
\echo ''
\echo 'To delete test orders:'
\echo 'DELETE FROM orders WHERE created_at > NOW() - INTERVAL ''1 hour'';'
\echo ''
\echo 'To reset product availability:'
\echo 'UPDATE products SET is_available = true, availability_status = ''available'' WHERE id = ''PRODUCT-UUID'';'
\echo ''


