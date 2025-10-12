-- Debug products in database
SELECT COUNT(*) as total_products FROM products WHERE status = 'approved' AND is_available = true;

SELECT id, title, status, is_available, rental_price FROM products LIMIT 10;

-- Check categories
SELECT COUNT(*) as total_categories FROM categories;

-- Check if there are any approved products
SELECT COUNT(*) as approved_products FROM products WHERE status = 'approved';

-- Check if there are any available products  
SELECT COUNT(*) as available_products FROM products WHERE is_available = true;

-- Check recent products
SELECT id, title, status, is_available, created_at FROM products ORDER BY created_at DESC LIMIT 5;
