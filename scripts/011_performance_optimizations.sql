-- Performance optimizations for Rentimade platform
-- This script adds database indexes and optimizations to improve query performance

-- Add indexes for frequently queried columns
CREATE INDEX IF NOT EXISTS idx_products_status ON public.products(status);
CREATE INDEX IF NOT EXISTS idx_products_owner_id ON public.products(owner_id);
CREATE INDEX IF NOT EXISTS idx_products_category_id ON public.products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_created_at ON public.products(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_products_is_available ON public.products(is_available);

-- Add indexes for orders table
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_owner_id ON public.orders(owner_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders(created_at DESC);

-- Add indexes for reviews table
CREATE INDEX IF NOT EXISTS idx_reviews_product_id ON public.reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON public.reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_status ON public.reviews(status);

-- Add indexes for profiles table
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON public.profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_is_admin ON public.profiles(is_admin);

-- Add composite indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_products_status_available ON public.products(status, is_available) WHERE is_available = true;
CREATE INDEX IF NOT EXISTS idx_orders_user_status ON public.orders(user_id, status);
CREATE INDEX IF NOT EXISTS idx_orders_owner_status ON public.orders(owner_id, status);

-- Optimize text search (if using full-text search)
-- CREATE INDEX IF NOT EXISTS idx_products_search ON public.products USING gin(to_tsvector('english', title || ' ' || description));

-- Add partial indexes for common filters
CREATE INDEX IF NOT EXISTS idx_products_approved_available ON public.products(id, title, rental_price, images) 
WHERE status = 'approved' AND is_available = true;

-- Optimize the product availability function
CREATE OR REPLACE FUNCTION check_product_availability_optimized(
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
    WHERE product_id = check_product_availability_optimized.product_id
      AND status IN ('pending', 'confirmed', 'shipped', 'delivered')
      AND (
        (rental_start_date <= check_product_availability_optimized.start_date AND rental_end_date >= check_product_availability_optimized.start_date)
        OR (rental_start_date <= check_product_availability_optimized.end_date AND rental_end_date >= check_product_availability_optimized.end_date)
        OR (rental_start_date >= check_product_availability_optimized.start_date AND rental_end_date <= check_product_availability_optimized.end_date)
      )
  );
END;
$$;

-- Update table statistics for better query planning
ANALYZE public.products;
ANALYZE public.orders;
ANALYZE public.reviews;
ANALYZE public.profiles;
ANALYZE public.categories;

-- Add comments for documentation
COMMENT ON INDEX idx_products_status IS 'Index for filtering products by status (pending, approved, rejected)';
COMMENT ON INDEX idx_products_owner_id IS 'Index for finding products by owner';
COMMENT ON INDEX idx_products_category_id IS 'Index for filtering products by category';
COMMENT ON INDEX idx_orders_user_id IS 'Index for finding orders by user';
COMMENT ON INDEX idx_orders_owner_id IS 'Index for finding orders by product owner';
