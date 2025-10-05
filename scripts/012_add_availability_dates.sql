-- Add availability date columns to products table
-- This script adds fields to track when dresses are available for rent

-- Add availability date columns
ALTER TABLE public.products
ADD COLUMN IF NOT EXISTS available_from DATE,
ADD COLUMN IF NOT EXISTS available_until DATE;

-- Add check constraint to ensure available_from is before available_until
ALTER TABLE public.products
ADD CONSTRAINT products_availability_dates_check 
CHECK (available_from IS NULL OR available_until IS NULL OR available_from <= available_until);

-- Add index for efficient date range queries
CREATE INDEX IF NOT EXISTS idx_products_availability_dates 
ON public.products(available_from, available_until) 
WHERE available_from IS NOT NULL AND available_until IS NOT NULL;

-- Update existing products to have default availability (available from now, for 1 year)
UPDATE public.products
SET 
  available_from = CURRENT_DATE,
  available_until = CURRENT_DATE + INTERVAL '1 year'
WHERE available_from IS NULL OR available_until IS NULL;

-- Add comments for documentation
COMMENT ON COLUMN public.products.available_from IS 'Date when the product becomes available for rent';
COMMENT ON COLUMN public.products.available_until IS 'Date when the product stops being available for rent';
COMMENT ON INDEX idx_products_availability_dates IS 'Index for efficient availability date range queries';
