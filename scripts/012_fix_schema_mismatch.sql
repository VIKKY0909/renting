-- Fix schema mismatches between code and database
-- Add missing columns that the application code expects

-- Add condition column to products table
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS condition TEXT;

-- Add payment_method column to orders table  
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS payment_method TEXT;

-- Update existing products with default condition
UPDATE public.products 
SET condition = 'good' 
WHERE condition IS NULL;

-- Update existing orders with default payment method
UPDATE public.orders 
SET payment_method = 'card' 
WHERE payment_method IS NULL;

-- Add check constraint for condition
ALTER TABLE public.products 
ADD CONSTRAINT IF NOT EXISTS products_condition_check 
CHECK (condition IN ('new', 'excellent', 'good', 'fair'));

-- Make condition NOT NULL after setting defaults
ALTER TABLE public.products 
ALTER COLUMN condition SET NOT NULL;

-- Make payment_method NOT NULL after setting defaults
ALTER TABLE public.orders 
ALTER COLUMN payment_method SET NOT NULL;

-- Add comments for documentation
COMMENT ON COLUMN public.products.condition IS 'Condition of the product (new, excellent, good, fair)';
COMMENT ON COLUMN public.orders.payment_method IS 'Payment method used for the order';
