-- Update category images with static image paths
-- Run this in your Supabase SQL Editor to update existing categories

UPDATE public.categories 
SET image_url = '/traditional-indian-lehenga.jpg'
WHERE slug = 'lehenga';

UPDATE public.categories 
SET image_url = '/designer-silk-saree.jpg'
WHERE slug = 'saree';

UPDATE public.categories 
SET image_url = '/elegant-designer-gown.jpg'
WHERE slug = 'gown';

UPDATE public.categories 
SET image_url = '/indo-western-outfit.jpg'
WHERE slug = 'indo-western';
