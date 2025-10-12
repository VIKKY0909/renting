-- Fix Products RLS Policy to allow anonymous users to view approved products

-- Drop the existing restrictive policy
DROP POLICY IF EXISTS "Anyone can view approved products" ON public.products;

-- Create a new policy that allows anonymous users to view approved products
CREATE POLICY "Anyone can view approved products" ON public.products FOR SELECT USING (
  status = 'approved' AND is_available = true
);

-- Also allow owners to see their own products (even if not approved)
CREATE POLICY "Owners can view own products" ON public.products FOR SELECT USING (
  auth.uid() = owner_id
);

-- Allow admins to see all products
CREATE POLICY "Admins can view all products" ON public.products FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true)
);
