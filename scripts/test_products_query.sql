-- Test the exact query that the frontend uses
-- This simulates what happens when getProducts() is called

-- 1. Test the exact query structure from lib/actions/products.ts
SELECT 
  p.id, 
  p.title, 
  p.description, 
  p.short_description, 
  p.brand, 
  p.color, 
  p.fabric, 
  p.occasion,
  p.rental_price, 
  p.security_deposit, 
  p.original_price, 
  p.bust, 
  p.waist, 
  p.length, 
  p.sleeve_length,
  p.images, 
  p.condition, 
  p.status, 
  p.is_available, 
  p.total_rentals, 
  p.average_rating,
  p.available_from, 
  p.available_until, 
  p.created_at, 
  p.updated_at,
  pr.id as owner_id,
  pr.full_name as owner_name,
  pr.avatar_url as owner_avatar,
  c.id as category_id,
  c.name as category_name,
  c.slug as category_slug
FROM products p
LEFT JOIN profiles pr ON p.owner_id = pr.id
LEFT JOIN categories c ON p.category_id = c.id
WHERE p.status = 'approved' 
  AND p.is_available = true
ORDER BY p.created_at DESC;

-- 2. Test with count (like the frontend does)
SELECT COUNT(*) as total_count
FROM products p
WHERE p.status = 'approved' 
  AND p.is_available = true;

-- 3. Test without any joins to see if that's the issue
SELECT id, title, status, is_available, category_id, owner_id
FROM products 
WHERE status = 'approved' 
  AND is_available = true
ORDER BY created_at DESC;

-- 4. Check if profiles table is accessible
SELECT COUNT(*) as profiles_count FROM profiles;

-- 5. Check if categories table is accessible  
SELECT COUNT(*) as categories_count FROM categories;
