-- Add admin_description field to products table
-- This field will contain the admin's description that overrides the user's description

ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS admin_description TEXT;

-- Add comment to explain the field
COMMENT ON COLUMN public.products.admin_description IS 'Admin-curated description that replaces user description when product is approved';
