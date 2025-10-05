-- Function to increment product views
CREATE OR REPLACE FUNCTION increment_product_views(product_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE public.products
  SET views = views + 1
  WHERE id = product_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get product statistics
CREATE OR REPLACE FUNCTION get_product_stats(product_id UUID)
RETURNS TABLE(
  total_orders BIGINT,
  total_revenue NUMERIC,
  average_rating NUMERIC,
  total_reviews BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(DISTINCT o.id) as total_orders,
    COALESCE(SUM(o.rental_price), 0) as total_revenue,
    COALESCE(AVG(r.rating), 0) as average_rating,
    COUNT(DISTINCT r.id) as total_reviews
  FROM public.products p
  LEFT JOIN public.orders o ON o.product_id = p.id AND o.status = 'completed'
  LEFT JOIN public.reviews r ON r.product_id = p.id AND r.status = 'approved'
  WHERE p.id = product_id
  GROUP BY p.id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user statistics
CREATE OR REPLACE FUNCTION get_user_stats(user_id UUID)
RETURNS TABLE(
  total_orders BIGINT,
  total_spent NUMERIC,
  total_listings BIGINT,
  total_earnings NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    (SELECT COUNT(*) FROM public.orders WHERE orders.user_id = user_id) as total_orders,
    (SELECT COALESCE(SUM(total_amount), 0) FROM public.orders WHERE orders.user_id = user_id AND status = 'completed') as total_spent,
    (SELECT COUNT(*) FROM public.products WHERE owner_id = user_id) as total_listings,
    (SELECT COALESCE(SUM(amount), 0) FROM public.earnings WHERE owner_id = user_id AND status = 'paid') as total_earnings;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check product availability for dates
CREATE OR REPLACE FUNCTION check_product_availability(
  product_id UUID,
  start_date DATE,
  end_date DATE
)
RETURNS BOOLEAN AS $$
DECLARE
  is_available BOOLEAN;
BEGIN
  SELECT NOT EXISTS (
    SELECT 1
    FROM public.orders
    WHERE orders.product_id = check_product_availability.product_id
      AND orders.status NOT IN ('cancelled', 'completed')
      AND (
        (orders.rental_start_date, orders.rental_end_date) OVERLAPS (start_date, end_date)
      )
  ) INTO is_available;
  
  RETURN is_available;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
