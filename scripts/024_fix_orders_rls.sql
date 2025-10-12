-- Fix RLS policies for orders table to ensure proper access
-- This script addresses the "fetch failed" error when accessing orders

-- First, let's check the current RLS status
SELECT 
    schemaname, 
    tablename, 
    rowsecurity as rls_enabled,
    hasrls as has_rls_policies
FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'orders';

-- Check existing policies on orders table
SELECT 
    policyname, 
    permissive, 
    roles, 
    cmd, 
    qual, 
    with_check
FROM pg_policies 
WHERE tablename = 'orders' AND schemaname = 'public';

-- Drop existing policies to recreate them properly
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can create orders" ON public.orders;
DROP POLICY IF EXISTS "Users and owners can update orders" ON public.orders;

-- Recreate RLS policies with better logic
-- Policy for SELECT (viewing orders)
CREATE POLICY "Users can view own orders" ON public.orders 
FOR SELECT USING (
    -- User can see their own orders
    auth.uid() = user_id 
    OR 
    -- Owner can see orders for their products
    auth.uid() = owner_id 
    OR 
    -- Admins can see all orders
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = auth.uid() AND is_admin = true
    )
);

-- Policy for INSERT (creating orders)
CREATE POLICY "Users can create orders" ON public.orders 
FOR INSERT WITH CHECK (
    -- User can only create orders for themselves
    auth.uid() = user_id
    AND
    -- Prevent self-rental
    auth.uid() != owner_id
);

-- Policy for UPDATE (updating orders)
CREATE POLICY "Users and owners can update orders" ON public.orders 
FOR UPDATE USING (
    -- User can update their own orders
    auth.uid() = user_id 
    OR 
    -- Owner can update orders for their products
    auth.uid() = owner_id 
    OR 
    -- Admins can update all orders
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = auth.uid() AND is_admin = true
    )
);

-- Policy for DELETE (deleting orders) - only admins should be able to delete
CREATE POLICY "Admins can delete orders" ON public.orders 
FOR DELETE USING (
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = auth.uid() AND is_admin = true
    )
);

-- Ensure RLS is enabled on orders table
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.orders TO authenticated;
GRANT ALL ON public.orders TO service_role;

-- Create indexes for better performance with RLS
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_owner_id ON public.orders(owner_id);
CREATE INDEX IF NOT EXISTS idx_orders_product_id ON public.orders(product_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders(created_at);

-- Verify the policies are created
SELECT 
    policyname, 
    permissive, 
    roles, 
    cmd, 
    qual
FROM pg_policies 
WHERE tablename = 'orders' AND schemaname = 'public'
ORDER BY policyname;

-- Test query to verify access
SELECT COUNT(*) as total_orders FROM public.orders;




