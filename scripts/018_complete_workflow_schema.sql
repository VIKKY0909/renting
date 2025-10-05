-- Complete Product Listing and Order Management Workflow Schema
-- This script creates the complete workflow for product listing, approval, and order management

-- Add missing columns to products table for better admin management
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS rejection_reason TEXT,
ADD COLUMN IF NOT EXISTS admin_notes TEXT,
ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES public.profiles(id),
ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS rejected_by UUID REFERENCES public.profiles(id),
ADD COLUMN IF NOT EXISTS rejected_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS condition_details TEXT,
ADD COLUMN IF NOT EXISTS care_instructions TEXT,
ADD COLUMN IF NOT EXISTS size_guide TEXT,
ADD COLUMN IF NOT EXISTS availability_status TEXT DEFAULT 'available' CHECK (availability_status IN ('available', 'rented', 'maintenance', 'unavailable'));

-- Update products status enum to include more detailed statuses
ALTER TABLE public.products DROP CONSTRAINT IF EXISTS products_status_check;
ALTER TABLE public.products ADD CONSTRAINT products_status_check 
CHECK (status IN ('pending', 'under_review', 'approved', 'rejected', 'suspended', 'unavailable'));

-- Update orders status enum for better tracking
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_status_check;
ALTER TABLE public.orders ADD CONSTRAINT orders_status_check 
CHECK (status IN ('pending', 'confirmed', 'picked_up', 'dispatched', 'delivered', 'picked_up_for_return', 'returned', 'completed', 'cancelled', 'rejected'));

-- Add missing columns to orders table for better tracking
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

-- Create order_status_history table for tracking status changes
CREATE TABLE IF NOT EXISTS public.order_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    status TEXT NOT NULL,
    payment_status TEXT,
    notes TEXT,
    updated_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create product_status_history table for tracking product status changes
CREATE TABLE IF NOT EXISTS public.product_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    status TEXT NOT NULL,
    reason TEXT,
    notes TEXT,
    updated_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create admin_notifications table for admin alerts
CREATE TABLE IF NOT EXISTS public.admin_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type TEXT NOT NULL CHECK (type IN ('new_product', 'new_order', 'order_status_change', 'payment_received', 'product_rejected', 'system_alert')),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    data JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    read_at TIMESTAMP WITH TIME ZONE
);

-- Create order_items table for multiple items per order (future expansion)
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
    quantity INTEGER DEFAULT 1,
    rental_price DECIMAL(10, 2) NOT NULL,
    security_deposit DECIMAL(10, 2) NOT NULL,
    discount DECIMAL(10, 2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create payment_transactions table for detailed payment tracking
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

-- Create inventory_tracking table for product availability
CREATE TABLE IF NOT EXISTS public.inventory_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN ('available', 'rented', 'maintenance', 'damaged', 'lost')),
    order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
    notes TEXT,
    changed_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create admin_dashboard_stats table for caching dashboard data
CREATE TABLE IF NOT EXISTS public.admin_dashboard_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    stat_date DATE NOT NULL,
    total_products INTEGER DEFAULT 0,
    pending_products INTEGER DEFAULT 0,
    approved_products INTEGER DEFAULT 0,
    rejected_products INTEGER DEFAULT 0,
    total_orders INTEGER DEFAULT 0,
    pending_orders INTEGER DEFAULT 0,
    confirmed_orders INTEGER DEFAULT 0,
    completed_orders INTEGER DEFAULT 0,
    cancelled_orders INTEGER DEFAULT 0,
    total_revenue DECIMAL(15, 2) DEFAULT 0,
    pending_payments DECIMAL(15, 2) DEFAULT 0,
    total_users INTEGER DEFAULT 0,
    active_users INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(stat_date)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_products_status ON public.products(status);
CREATE INDEX IF NOT EXISTS idx_products_owner_id ON public.products(owner_id);
CREATE INDEX IF NOT EXISTS idx_products_approved_by ON public.products(approved_by);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_owner_id ON public.orders(owner_id);
CREATE INDEX IF NOT EXISTS idx_orders_payment_status ON public.orders(payment_status);
CREATE INDEX IF NOT EXISTS idx_order_status_history_order_id ON public.order_status_history(order_id);
CREATE INDEX IF NOT EXISTS idx_product_status_history_product_id ON public.product_status_history(product_id);
CREATE INDEX IF NOT EXISTS idx_admin_notifications_is_read ON public.admin_notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_order_id ON public.payment_transactions(order_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON public.payment_transactions(status);

-- Create functions for automatic status tracking

-- Function to track order status changes
CREATE OR REPLACE FUNCTION track_order_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status OR OLD.payment_status IS DISTINCT FROM NEW.payment_status THEN
        INSERT INTO public.order_status_history (order_id, status, payment_status, notes, updated_by)
        VALUES (NEW.id, NEW.status, NEW.payment_status, 'Status updated', NEW.status_updated_by);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to track product status changes
CREATE OR REPLACE FUNCTION track_product_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO public.product_status_history (product_id, status, reason, notes, updated_by)
        VALUES (NEW.id, NEW.status, NEW.rejection_reason, NEW.admin_notes, NEW.approved_by);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to create admin notifications
CREATE OR REPLACE FUNCTION create_admin_notification(
    notification_type TEXT,
    notification_title TEXT,
    notification_message TEXT,
    notification_data JSONB DEFAULT NULL,
    notification_priority TEXT DEFAULT 'medium'
)
RETURNS UUID AS $$
DECLARE
    notification_id UUID;
BEGIN
    INSERT INTO public.admin_notifications (type, title, message, data, priority)
    VALUES (notification_type, notification_title, notification_message, notification_data, notification_priority)
    RETURNING id INTO notification_id;
    
    RETURN notification_id;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for automatic tracking
DROP TRIGGER IF EXISTS trigger_track_order_status_change ON public.orders;
CREATE TRIGGER trigger_track_order_status_change
    AFTER UPDATE ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION track_order_status_change();

DROP TRIGGER IF EXISTS trigger_track_product_status_change ON public.products;
CREATE TRIGGER trigger_track_product_status_change
    AFTER UPDATE ON public.products
    FOR EACH ROW
    EXECUTE FUNCTION track_product_status_change();

-- Enable Row Level Security on new tables
ALTER TABLE public.order_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_dashboard_stats ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for new tables

-- Order status history policies
CREATE POLICY "Users can view their own order history" ON public.order_status_history
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE orders.id = order_status_history.order_id 
            AND orders.user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can view all order history" ON public.order_status_history
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.is_admin = true
        )
    );

-- Product status history policies
CREATE POLICY "Product owners can view their product history" ON public.product_status_history
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.products 
            WHERE products.id = product_status_history.product_id 
            AND products.owner_id = auth.uid()
        )
    );

CREATE POLICY "Admins can view all product history" ON public.product_status_history
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.is_admin = true
        )
    );

-- Admin notifications policies
CREATE POLICY "Admins can manage notifications" ON public.admin_notifications
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.is_admin = true
        )
    );

-- Order items policies
CREATE POLICY "Users can view their order items" ON public.order_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE orders.id = order_items.order_id 
            AND orders.user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage order items" ON public.order_items
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.is_admin = true
        )
    );

-- Payment transactions policies
CREATE POLICY "Users can view their payment transactions" ON public.payment_transactions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE orders.id = payment_transactions.order_id 
            AND orders.user_id = auth.uid()
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

-- Inventory tracking policies
CREATE POLICY "Product owners can view their inventory" ON public.inventory_tracking
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.products 
            WHERE products.id = inventory_tracking.product_id 
            AND products.owner_id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage inventory" ON public.inventory_tracking
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.is_admin = true
        )
    );

-- Admin dashboard stats policies
CREATE POLICY "Admins can view dashboard stats" ON public.admin_dashboard_stats
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.is_admin = true
        )
    );

-- Grant permissions
GRANT ALL ON public.order_status_history TO authenticated;
GRANT ALL ON public.product_status_history TO authenticated;
GRANT ALL ON public.admin_notifications TO authenticated;
GRANT ALL ON public.order_items TO authenticated;
GRANT ALL ON public.payment_transactions TO authenticated;
GRANT ALL ON public.inventory_tracking TO authenticated;
GRANT ALL ON public.admin_dashboard_stats TO authenticated;

-- Insert sample admin notifications
INSERT INTO public.admin_notifications (type, title, message, priority) VALUES 
    ('system_alert', 'System Setup Complete', 'The complete product listing and order management workflow has been set up successfully.', 'high'),
    ('system_alert', 'Database Schema Updated', 'All tables and functions for the workflow have been created.', 'medium');

-- Create views for easier querying

-- View for pending products awaiting approval
CREATE OR REPLACE VIEW pending_products_view AS
SELECT 
    p.*,
    pr.full_name as owner_name,
    pr.email as owner_email,
    pr.phone as owner_phone,
    c.name as category_name
FROM public.products p
JOIN public.profiles pr ON p.owner_id = pr.id
JOIN public.categories c ON p.category_id = c.id
WHERE p.status IN ('pending', 'under_review')
ORDER BY p.created_at DESC;

-- View for active orders with details
CREATE OR REPLACE VIEW active_orders_view AS
SELECT 
    o.*,
    pr.full_name as customer_name,
    pr.email as customer_email,
    pr.phone as customer_phone,
    po.full_name as owner_name,
    po.email as owner_email,
    p.title as product_title,
    p.images as product_images
FROM public.orders o
JOIN public.profiles pr ON o.user_id = pr.id
JOIN public.profiles po ON o.owner_id = po.id
JOIN public.products p ON o.product_id = p.id
WHERE o.status NOT IN ('completed', 'cancelled', 'rejected')
ORDER BY o.created_at DESC;

-- View for admin dashboard summary
CREATE OR REPLACE VIEW admin_dashboard_summary AS
SELECT 
    (SELECT COUNT(*) FROM public.products WHERE status = 'pending') as pending_products,
    (SELECT COUNT(*) FROM public.products WHERE status = 'approved') as approved_products,
    (SELECT COUNT(*) FROM public.products WHERE status = 'rejected') as rejected_products,
    (SELECT COUNT(*) FROM public.orders WHERE status = 'pending') as pending_orders,
    (SELECT COUNT(*) FROM public.orders WHERE status = 'confirmed') as confirmed_orders,
    (SELECT COUNT(*) FROM public.orders WHERE status = 'delivered') as delivered_orders,
    (SELECT COUNT(*) FROM public.orders WHERE status = 'completed') as completed_orders,
    (SELECT COUNT(*) FROM public.orders WHERE status = 'cancelled') as cancelled_orders,
    (SELECT COUNT(*) FROM public.profiles WHERE is_admin = false) as total_users,
    (SELECT COUNT(*) FROM public.profiles WHERE is_admin = true) as total_admins;

-- Grant permissions on views
GRANT SELECT ON pending_products_view TO authenticated;
GRANT SELECT ON active_orders_view TO authenticated;
GRANT SELECT ON admin_dashboard_summary TO authenticated;
