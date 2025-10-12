-- =====================================================
-- FIX PRODUCTS TABLE MISSING COLUMNS
-- This script adds missing columns to the products table
-- =====================================================

-- Add missing columns to products table
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS status_updated_by UUID REFERENCES public.profiles(id),
ADD COLUMN IF NOT EXISTS status_updated_at TIMESTAMP WITH TIME ZONE;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_products_status_updated_by ON public.products(status_updated_by);
CREATE INDEX IF NOT EXISTS idx_products_status_updated_at ON public.products(status_updated_at);

-- Update existing products to have status_updated_at set to updated_at if null
UPDATE public.products 
SET status_updated_at = updated_at 
WHERE status_updated_at IS NULL AND updated_at IS NOT NULL;

-- Add comments for documentation
COMMENT ON COLUMN public.products.status_updated_by IS 'ID of the admin user who last updated the product status';
COMMENT ON COLUMN public.products.status_updated_at IS 'Timestamp when the product status was last updated';

-- Verify the changes
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'products' 
AND table_schema = 'public'
AND column_name IN ('status_updated_by', 'status_updated_at')
ORDER BY ordinal_position;
