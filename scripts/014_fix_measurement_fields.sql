-- Fix measurement fields to handle proper data types and ranges
-- This script updates the products table to handle measurements correctly

-- Update bust, waist, length fields to allow larger values (up to 9999.99)
ALTER TABLE public.products 
ALTER COLUMN bust TYPE NUMERIC(6,2);

ALTER TABLE public.products 
ALTER COLUMN waist TYPE NUMERIC(6,2);

ALTER TABLE public.products 
ALTER COLUMN length TYPE NUMERIC(6,2);

-- Change sleeve_length from numeric to text to handle descriptive values
ALTER TABLE public.products 
ALTER COLUMN sleeve_length TYPE TEXT;

-- Add check constraints for valid sleeve length values
ALTER TABLE public.products 
ADD CONSTRAINT products_sleeve_length_check 
CHECK (sleeve_length IN ('sleeveless', 'short', '3/4', 'full'));

-- Add check constraints for reasonable measurement ranges
ALTER TABLE public.products 
ADD CONSTRAINT products_bust_check 
CHECK (bust IS NULL OR (bust >= 20 AND bust <= 200));

ALTER TABLE public.products 
ADD CONSTRAINT products_waist_check 
CHECK (waist IS NULL OR (waist >= 15 AND waist <= 150));

ALTER TABLE public.products 
ADD CONSTRAINT products_length_check 
CHECK (length IS NULL OR (length >= 20 AND length <= 300));

-- Add comments for documentation
COMMENT ON COLUMN public.products.bust IS 'Bust measurement in inches (20-200)';
COMMENT ON COLUMN public.products.waist IS 'Waist measurement in inches (15-150)';
COMMENT ON COLUMN public.products.length IS 'Length measurement in inches (20-300)';
COMMENT ON COLUMN public.products.sleeve_length IS 'Sleeve length description (sleeveless, short, 3/4, full)';
