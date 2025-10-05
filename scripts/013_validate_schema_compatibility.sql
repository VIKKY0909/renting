-- Schema validation script to ensure all application code matches database schema
-- This script validates that all expected columns exist and have correct types

-- Check if all required columns exist in products table
DO $$
BEGIN
    -- Check products table columns
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'condition') THEN
        RAISE NOTICE 'Adding missing condition column to products table';
        ALTER TABLE public.products ADD COLUMN condition TEXT;
        UPDATE public.products SET condition = 'good' WHERE condition IS NULL;
        ALTER TABLE public.products ALTER COLUMN condition SET NOT NULL;
        ALTER TABLE public.products ADD CONSTRAINT products_condition_check CHECK (condition IN ('new', 'excellent', 'good', 'fair'));
    END IF;

    -- Check orders table columns
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'payment_method') THEN
        RAISE NOTICE 'Adding missing payment_method column to orders table';
        ALTER TABLE public.orders ADD COLUMN payment_method TEXT;
        UPDATE public.orders SET payment_method = 'card' WHERE payment_method IS NULL;
        ALTER TABLE public.orders ALTER COLUMN payment_method SET NOT NULL;
    END IF;

    -- Verify all expected columns exist
    RAISE NOTICE 'Validating products table schema...';
    
    -- Check required columns exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'bust') THEN
        RAISE EXCEPTION 'Missing required column: products.bust';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'waist') THEN
        RAISE EXCEPTION 'Missing required column: products.waist';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'length') THEN
        RAISE EXCEPTION 'Missing required column: products.length';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'sleeve_length') THEN
        RAISE EXCEPTION 'Missing required column: products.sleeve_length';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'occasion') THEN
        RAISE EXCEPTION 'Missing required column: products.occasion';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'images') THEN
        RAISE EXCEPTION 'Missing required column: products.images';
    END IF;
    
    RAISE NOTICE 'Products table schema validation passed!';
    
    -- Validate orders table
    RAISE NOTICE 'Validating orders table schema...';
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'payment_method') THEN
        RAISE EXCEPTION 'Missing required column: orders.payment_method';
    END IF;
    
    RAISE NOTICE 'Orders table schema validation passed!';
    
    -- Validate categories table
    RAISE NOTICE 'Validating categories table schema...';
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'categories' AND column_name = 'slug') THEN
        RAISE EXCEPTION 'Missing required column: categories.slug';
    END IF;
    
    RAISE NOTICE 'Categories table schema validation passed!';
    
    RAISE NOTICE 'All schema validations passed successfully!';
END $$;

-- Create or update the product availability function
CREATE OR REPLACE FUNCTION check_product_availability(
  product_id UUID,
  start_date DATE,
  end_date DATE
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN NOT EXISTS (
    SELECT 1 
    FROM public.orders 
    WHERE product_id = check_product_availability.product_id
      AND status IN ('pending', 'confirmed', 'shipped', 'delivered')
      AND (
        (rental_start_date <= check_product_availability.start_date AND rental_end_date >= check_product_availability.start_date)
        OR (rental_start_date <= check_product_availability.end_date AND rental_end_date >= check_product_availability.end_date)
        OR (rental_start_date >= check_product_availability.start_date AND rental_end_date <= check_product_availability.end_date)
      )
  );
END;
$$;

-- Add comments for documentation
COMMENT ON FUNCTION check_product_availability(UUID, DATE, DATE) IS 'Check if a product is available for rental during the specified date range';

-- Verify the function works
SELECT check_product_availability('00000000-0000-0000-0000-000000000000', '2025-01-01', '2025-01-03') as test_result;
