-- Check Products Status and Visibility
-- This script helps debug why products are not visible

-- Check all products with their status and availability
SELECT 
    id,
    title,
    status,
    is_available,
    listed_by_admin,
    owner_id,
    created_at,
    approved_at
FROM public.products 
ORDER BY created_at DESC;

-- Check if there are any approved products that should be visible
SELECT 
    COUNT(*) as total_products,
    COUNT(CASE WHEN status = 'approved' THEN 1 END) as approved_products,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_products,
    COUNT(CASE WHEN status = 'rejected' THEN 1 END) as rejected_products,
    COUNT(CASE WHEN is_available = true THEN 1 END) as available_products,
    COUNT(CASE WHEN status = 'approved' AND is_available = true THEN 1 END) as visible_products
FROM public.products;

-- Check products that should be visible to public (approved and available)
SELECT 
    p.id,
    p.title,
    p.status,
    p.is_available,
    p.listed_by_admin,
    pr.full_name as owner_name,
    pr.role as owner_role
FROM public.products p
JOIN public.profiles pr ON p.owner_id = pr.id
WHERE p.status = 'approved' AND p.is_available = true
ORDER BY p.created_at DESC;

-- Check if there are any issues with the products
SELECT 
    id,
    title,
    status,
    is_available,
    CASE 
        WHEN status = 'approved' AND is_available = true THEN 'SHOULD BE VISIBLE'
        WHEN status = 'approved' AND is_available = false THEN 'APPROVED BUT UNAVAILABLE'
        WHEN status = 'pending' THEN 'PENDING APPROVAL'
        WHEN status = 'rejected' THEN 'REJECTED'
        ELSE 'OTHER STATUS'
    END as visibility_status
FROM public.products
ORDER BY created_at DESC;




