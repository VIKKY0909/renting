-- Complete schema fixes for Rentimade platform
-- This script addresses all known schema issues

-- 1. Fix condition column (make it optional with default)
ALTER TABLE public.products 
ALTER COLUMN condition DROP NOT NULL;

ALTER TABLE public.products 
ALTER COLUMN condition SET DEFAULT 'good';

-- Update any existing NULL values
UPDATE public.products 
SET condition = 'good' 
WHERE condition IS NULL;

-- Update check constraint to allow NULL
ALTER TABLE public.products 
DROP CONSTRAINT IF EXISTS products_condition_check;

ALTER TABLE public.products 
ADD CONSTRAINT products_condition_check 
CHECK (condition IS NULL OR condition IN ('new', 'excellent', 'good', 'fair'));

-- 2. Fix measurement fields (allow larger values)
ALTER TABLE public.products 
ALTER COLUMN bust TYPE NUMERIC(6,2);

ALTER TABLE public.products 
ALTER COLUMN waist TYPE NUMERIC(6,2);

ALTER TABLE public.products 
ALTER COLUMN length TYPE NUMERIC(6,2);

-- 3. Fix sleeve_length field (change to text)
ALTER TABLE public.products 
ALTER COLUMN sleeve_length TYPE TEXT;

-- Add check constraint for valid sleeve length values
ALTER TABLE public.products 
DROP CONSTRAINT IF EXISTS products_sleeve_length_check;

ALTER TABLE public.products 
ADD CONSTRAINT products_sleeve_length_check 
CHECK (sleeve_length IN ('sleeveless', 'short', '3/4', 'full'));

-- 4. Add payment_method to orders if not exists
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'card';

-- 5. Add check constraints for reasonable measurement ranges
ALTER TABLE public.products 
DROP CONSTRAINT IF EXISTS products_bust_check;

ALTER TABLE public.products 
ADD CONSTRAINT products_bust_check 
CHECK (bust IS NULL OR (bust >= 20 AND bust <= 200));

ALTER TABLE public.products 
DROP CONSTRAINT IF EXISTS products_waist_check;

ALTER TABLE public.products 
ADD CONSTRAINT products_waist_check 
CHECK (waist IS NULL OR (waist >= 15 AND waist <= 150));

ALTER TABLE public.products 
DROP CONSTRAINT IF EXISTS products_length_check;

ALTER TABLE public.products 
ADD CONSTRAINT products_length_check 
CHECK (length IS NULL OR (length >= 20 AND length <= 300));

-- 6. Add performance indexes
CREATE INDEX IF NOT EXISTS idx_products_status ON public.products(status);
CREATE INDEX IF NOT EXISTS idx_products_owner_id ON public.products(owner_id);
CREATE INDEX IF NOT EXISTS idx_products_category_id ON public.products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_created_at ON public.products(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_products_is_available ON public.products(is_available);

CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_owner_id ON public.orders(owner_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders(created_at DESC);

-- 7. Add comments for documentation
COMMENT ON COLUMN public.products.condition IS 'Condition of the product (new, excellent, good, fair) - optional field with default "good"';
COMMENT ON COLUMN public.products.sleeve_length IS 'Sleeve length description (sleeveless, short, 3/4, full)';
COMMENT ON COLUMN public.products.bust IS 'Bust measurement in inches (20-200)';
COMMENT ON COLUMN public.products.waist IS 'Waist measurement in inches (15-150)';
COMMENT ON COLUMN public.products.length IS 'Length measurement in inches (20-300)';
COMMENT ON COLUMN public.orders.payment_method IS 'Payment method used for the order';

-- 8. Verify the changes
SELECT 
  column_name, 
  data_type, 
  is_nullable, 
  column_default
FROM information_schema.columns 
WHERE table_name = 'products' 
  AND column_name IN ('condition', 'bust', 'waist', 'length', 'sleeve_length')
ORDER BY column_name;
