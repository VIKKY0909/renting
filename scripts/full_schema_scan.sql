-- FULL SCHEMA SCAN FOR PRODUCTS ISSUE

-- 1. Check products table structure
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'products' 
ORDER BY ordinal_position;

-- 2. Check all products with full details
SELECT 
  id, 
  title, 
  status, 
  is_available, 
  category_id,
  owner_id,
  created_at,
  updated_at
FROM products 
ORDER BY created_at DESC;

-- 3. Check categories table
SELECT id, name, slug, created_at FROM categories ORDER BY id;

-- 4. Check products with category joins
SELECT 
  p.id, 
  p.title, 
  p.status, 
  p.is_available, 
  p.category_id,
  c.name as category_name,
  c.slug as category_slug,
  CASE 
    WHEN c.id IS NULL THEN 'NO CATEGORY'
    ELSE 'HAS CATEGORY'
  END as category_status
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
WHERE p.status = 'approved' AND p.is_available = true
ORDER BY p.created_at DESC;

-- 5. Check RLS policies on products table
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'products';

-- 6. Check if RLS is enabled on products
SELECT schemaname, tablename, rowsecurity, relforcerowsecurity
FROM pg_tables 
WHERE tablename = 'products';

-- 7. Check owner profiles
SELECT 
  p.id as product_id,
  p.title,
  p.owner_id,
  pr.id as profile_id,
  pr.full_name,
  pr.is_admin
FROM products p
LEFT JOIN profiles pr ON p.owner_id = pr.id
WHERE p.status = 'approved' AND p.is_available = true
ORDER BY p.created_at DESC;

-- 8. Count by status
SELECT 
  status,
  COUNT(*) as count
FROM products 
GROUP BY status;

-- 9. Count by availability
SELECT 
  is_available,
  COUNT(*) as count
FROM products 
GROUP BY is_available;

-- 10. Check for any constraints or triggers
SELECT 
  tc.constraint_name, 
  tc.constraint_type,
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
WHERE tc.table_name='products';
