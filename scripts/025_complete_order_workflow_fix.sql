-- =====================================================
-- COMPLETE ORDER WORKFLOW FIX
-- This script ensures all order management columns exist
-- and the complete workflow is functional
-- =====================================================

-- Add payment_method column if it doesn't exist
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'card' CHECK (payment_method IN ('card', 'upi', 'netbanking', 'cod'));

-- Ensure all workflow tracking columns exist
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS admin_notes TEXT,
ADD COLUMN IF NOT EXISTS customer_notes TEXT,
ADD COLUMN IF NOT EXISTS pickup_address TEXT,
ADD COLUMN IF NOT EXISTS delivery_address TEXT,
ADD COLUMN IF NOT EXISTS pickup_scheduled_date TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS delivery_scheduled_date TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS return_scheduled_date TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS actual_pickup_date TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS actual_delivery_date TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS actual_return_date TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS shipping_cost DECIMAL(10, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS late_fee DECIMAL(10, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS damage_fee DECIMAL(10, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS final_amount DECIMAL(10, 2),
ADD COLUMN IF NOT EXISTS refund_amount DECIMAL(10, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS status_updated_by UUID REFERENCES public.profiles(id),
ADD COLUMN IF NOT EXISTS status_updated_at TIMESTAMP WITH TIME ZONE;

-- Update orders status constraint to include all statuses
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_status_check;
ALTER TABLE public.orders ADD CONSTRAINT orders_status_check 
CHECK (status IN ('pending', 'confirmed', 'picked_up', 'dispatched', 'delivered', 'picked_up_for_return', 'returned', 'completed', 'cancelled', 'rejected'));

-- Update payment status constraint
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_payment_status_check;
ALTER TABLE public.orders ADD CONSTRAINT orders_payment_status_check 
CHECK (payment_status IN ('pending', 'paid', 'refunded', 'failed'));

-- Create order_status_history table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.order_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    status TEXT NOT NULL,
    payment_status TEXT,
    notes TEXT,
    updated_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create payment_transactions table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.payment_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    transaction_id TEXT UNIQUE,
    amount DECIMAL(10, 2) NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('rental', 'security_deposit', 'shipping', 'late_fee', 'damage_fee', 'refund')),
    status TEXT NOT NULL CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'refunded')),
    payment_method TEXT,
    gateway_response JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_payment_status ON public.orders(payment_status);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_owner_id ON public.orders(owner_id);
CREATE INDEX IF NOT EXISTS idx_orders_product_id ON public.orders(product_id);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders(created_at);
CREATE INDEX IF NOT EXISTS idx_orders_rental_dates ON public.orders(rental_start_date, rental_end_date);
CREATE INDEX IF NOT EXISTS idx_order_status_history_order_id ON public.order_status_history(order_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_order_id ON public.payment_transactions(order_id);

-- Function to track order status changes
CREATE OR REPLACE FUNCTION track_order_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Only log if status or payment status changed
    IF OLD.status IS DISTINCT FROM NEW.status OR OLD.payment_status IS DISTINCT FROM NEW.payment_status THEN
        INSERT INTO public.order_status_history (order_id, status, payment_status, notes, updated_by)
        VALUES (NEW.id, NEW.status, NEW.payment_status, 'Status updated', NEW.status_updated_by);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatic status tracking
DROP TRIGGER IF EXISTS trigger_track_order_status_change ON public.orders;
CREATE TRIGGER trigger_track_order_status_change
    AFTER UPDATE ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION track_order_status_change();

-- Enable Row Level Security on tables
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_transactions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to recreate them properly
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can create orders" ON public.orders;
DROP POLICY IF EXISTS "Users and owners can update orders" ON public.orders;
DROP POLICY IF EXISTS "Admins can delete orders" ON public.orders;

-- Recreate RLS policies with better logic for orders
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

CREATE POLICY "Users can create orders" ON public.orders 
FOR INSERT WITH CHECK (
    -- User can only create orders for themselves
    auth.uid() = user_id
    AND
    -- Prevent self-rental
    auth.uid() != owner_id
);

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

CREATE POLICY "Admins can delete orders" ON public.orders 
FOR DELETE USING (
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = auth.uid() AND is_admin = true
    )
);

-- Order status history policies
DROP POLICY IF EXISTS "Users can view their own order history" ON public.order_status_history;
DROP POLICY IF EXISTS "Admins can view all order history" ON public.order_status_history;

CREATE POLICY "Users can view their own order history" ON public.order_status_history
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE orders.id = order_status_history.order_id 
            AND (orders.user_id = auth.uid() OR orders.owner_id = auth.uid())
        )
    );

CREATE POLICY "Admins can manage all order history" ON public.order_status_history
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.is_admin = true
        )
    );

-- Payment transactions policies
DROP POLICY IF EXISTS "Users can view their payment transactions" ON public.payment_transactions;
DROP POLICY IF EXISTS "Admins can manage payment transactions" ON public.payment_transactions;

CREATE POLICY "Users can view their payment transactions" ON public.payment_transactions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE orders.id = payment_transactions.order_id 
            AND (orders.user_id = auth.uid() OR orders.owner_id = auth.uid())
        )
    );

CREATE POLICY "Admins can manage payment transactions" ON public.payment_transactions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.is_admin = true
        )
    );

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.orders TO authenticated;
GRANT SELECT, INSERT ON public.order_status_history TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.payment_transactions TO authenticated;
GRANT ALL ON public.orders TO service_role;
GRANT ALL ON public.order_status_history TO service_role;
GRANT ALL ON public.payment_transactions TO service_role;

-- Create function to get order statistics
CREATE OR REPLACE FUNCTION get_order_statistics(user_uuid UUID DEFAULT NULL)
RETURNS TABLE (
    total_orders BIGINT,
    pending_orders BIGINT,
    confirmed_orders BIGINT,
    delivered_orders BIGINT,
    completed_orders BIGINT,
    cancelled_orders BIGINT,
    total_revenue NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_orders,
        COUNT(*) FILTER (WHERE status = 'pending') as pending_orders,
        COUNT(*) FILTER (WHERE status = 'confirmed') as confirmed_orders,
        COUNT(*) FILTER (WHERE status = 'delivered') as delivered_orders,
        COUNT(*) FILTER (WHERE status = 'completed') as completed_orders,
        COUNT(*) FILTER (WHERE status = 'cancelled') as cancelled_orders,
        COALESCE(SUM(total_amount) FILTER (WHERE status = 'completed'), 0) as total_revenue
    FROM public.orders
    WHERE user_uuid IS NULL OR user_id = user_uuid OR owner_id = user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create view for admin order management
CREATE OR REPLACE VIEW admin_orders_view AS
SELECT 
    o.*,
    customer.full_name as customer_name,
    customer.email as customer_email,
    customer.phone as customer_phone,
    customer.city as customer_city,
    customer.state as customer_state,
    owner.full_name as owner_name,
    owner.email as owner_email,
    owner.phone as owner_phone,
    owner.city as owner_city,
    owner.state as owner_state,
    p.title as product_title,
    p.images as product_images,
    p.rental_price as product_rental_price,
    p.security_deposit as product_security_deposit,
    updater.full_name as updated_by_name
FROM public.orders o
JOIN public.profiles customer ON o.user_id = customer.id
JOIN public.profiles owner ON o.owner_id = owner.id
JOIN public.products p ON o.product_id = p.id
LEFT JOIN public.profiles updater ON o.status_updated_by = updater.id
ORDER BY o.created_at DESC;

-- Grant permissions on view
GRANT SELECT ON admin_orders_view TO authenticated;

-- Verify the schema
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'orders' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Show current RLS policies
SELECT 
    schemaname, 
    tablename, 
    policyname, 
    permissive, 
    roles, 
    cmd
FROM pg_policies 
WHERE tablename IN ('orders', 'order_status_history', 'payment_transactions')
AND schemaname = 'public'
ORDER BY tablename, policyname;

COMMENT ON TABLE public.orders IS 'Complete order management with full workflow tracking';
COMMENT ON COLUMN public.orders.payment_method IS 'Payment method: card, upi, netbanking, or cod';
COMMENT ON COLUMN public.orders.status_updated_by IS 'User ID who last updated the order status';
COMMENT ON VIEW admin_orders_view IS 'Comprehensive view of orders with customer, owner, and product details for admin dashboard';



