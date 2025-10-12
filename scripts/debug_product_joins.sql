-- Debug product joins and categories
SELECT 
  p.id, 
  p.title, 
  p.status, 
  p.is_available, 
  p.category_id,
  c.name as category_name,
  c.slug as category_slug
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
WHERE p.status = 'approved' AND p.is_available = true
ORDER BY p.created_at DESC;

-- Check if categories exist
SELECT COUNT(*) as total_categories FROM categories;

-- Check products without categories
SELECT COUNT(*) as products_without_category 
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
WHERE p.status = 'approved' AND p.is_available = true AND c.id IS NULL;

-- Check if categories table has data
SELECT id, name, slug FROM categories LIMIT 5;
