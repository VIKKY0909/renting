-- Add missing fields to products table
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS condition TEXT,
ADD COLUMN IF NOT EXISTS bust_size INTEGER,
ADD COLUMN IF NOT EXISTS waist_size INTEGER,
ADD COLUMN IF NOT EXISTS length_size INTEGER;

-- Update existing records to have default values
UPDATE public.products 
SET 
  condition = 'excellent',
  bust_size = 34,
  waist_size = 28,
  length_size = 42
WHERE condition IS NULL;

-- Add constraints
ALTER TABLE public.products 
ADD CONSTRAINT check_condition 
CHECK (condition IN ('new', 'excellent', 'good', 'fair'));

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_products_condition ON public.products(condition);
CREATE INDEX IF NOT EXISTS idx_products_bust_size ON public.products(bust_size);
CREATE INDEX IF NOT EXISTS idx_products_waist_size ON public.products(waist_size);
CREATE INDEX IF NOT EXISTS idx_products_length_size ON public.products(length_size);
