-- Fix condition column issue
-- Make condition column optional or provide default value

-- Option 1: Make condition column optional (remove NOT NULL constraint)
ALTER TABLE public.products 
ALTER COLUMN condition DROP NOT NULL;

-- Set default value for condition column
ALTER TABLE public.products 
ALTER COLUMN condition SET DEFAULT 'good';

-- Update any existing NULL values
UPDATE public.products 
SET condition = 'good' 
WHERE condition IS NULL;

-- Keep the check constraint for valid values
ALTER TABLE public.products 
DROP CONSTRAINT IF EXISTS products_condition_check;

ALTER TABLE public.products 
ADD CONSTRAINT products_condition_check 
CHECK (condition IS NULL OR condition IN ('new', 'excellent', 'good', 'fair'));

-- Add comment
COMMENT ON COLUMN public.products.condition IS 'Condition of the product (new, excellent, good, fair) - optional field';
