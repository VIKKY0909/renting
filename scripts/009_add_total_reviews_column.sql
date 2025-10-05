-- Add total_reviews column to products table
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS total_reviews INTEGER DEFAULT 0;

-- Add available_from and available_until columns for product availability
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS available_from DATE,
ADD COLUMN IF NOT EXISTS available_until DATE;

-- Add condition column if it doesn't exist
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS condition TEXT DEFAULT 'good';

-- Update existing products to have default values
UPDATE public.products 
SET total_reviews = 0 
WHERE total_reviews IS NULL;

UPDATE public.products 
SET condition = 'good' 
WHERE condition IS NULL;

-- Create function to update total_reviews when reviews are added/removed
CREATE OR REPLACE FUNCTION update_product_review_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.products 
    SET total_reviews = total_reviews + 1 
    WHERE id = NEW.product_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.products 
    SET total_reviews = total_reviews - 1 
    WHERE id = OLD.product_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update total_reviews
DROP TRIGGER IF EXISTS trigger_update_product_review_count ON public.reviews;
CREATE TRIGGER trigger_update_product_review_count
  AFTER INSERT OR DELETE ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION update_product_review_count();

-- Update total_reviews for existing products based on current reviews
UPDATE public.products 
SET total_reviews = (
  SELECT COUNT(*) 
  FROM public.reviews 
  WHERE reviews.product_id = products.id 
  AND reviews.status = 'approved'
);
