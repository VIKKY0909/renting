-- Fix Missing Columns and Issues
-- This script adds the missing columns and fixes the existing issues

-- Add missing columns to products table
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS listed_by_admin BOOLEAN DEFAULT FALSE;

-- Add missing columns to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin', 'super_admin')),
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS last_login TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS login_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES public.profiles(id),
ADD COLUMN IF NOT EXISTS notes TEXT;

-- Update existing admin users to have proper role
UPDATE public.profiles 
SET role = CASE 
    WHEN is_admin = TRUE THEN 'admin'
    ELSE 'user'
END
WHERE role IS NULL;

-- Create user_activity table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.user_activity (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    activity_type TEXT NOT NULL CHECK (activity_type IN (
        'login', 'logout', 'product_created', 'product_updated', 'product_deleted',
        'order_placed', 'order_cancelled', 'order_completed', 'profile_updated',
        'review_created', 'review_updated', 'wishlist_added', 'wishlist_removed'
    )),
    activity_description TEXT NOT NULL,
    metadata JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_is_active ON public.profiles(is_active);
CREATE INDEX IF NOT EXISTS idx_profiles_last_login ON public.profiles(last_login);
CREATE INDEX IF NOT EXISTS idx_products_listed_by_admin ON public.products(listed_by_admin);
CREATE INDEX IF NOT EXISTS idx_user_activity_user_id ON public.user_activity(user_id);
CREATE INDEX IF NOT EXISTS idx_user_activity_type ON public.user_activity(activity_type);
CREATE INDEX IF NOT EXISTS idx_user_activity_created_at ON public.user_activity(created_at);

-- Enable RLS on user_activity
ALTER TABLE public.user_activity ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for user_activity
DROP POLICY IF EXISTS "Users can view their own activity" ON public.user_activity;
CREATE POLICY "Users can view their own activity" ON public.user_activity
    FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Admins can view all activity" ON public.user_activity;
CREATE POLICY "Admins can view all activity" ON public.user_activity
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role IN ('admin', 'super_admin')
        )
    );

-- Grant permissions
GRANT ALL ON public.user_activity TO authenticated;

-- Create function to log user activity
CREATE OR REPLACE FUNCTION log_user_activity(
    activity_user_id UUID,
    activity_type TEXT,
    activity_description TEXT,
    activity_metadata JSONB DEFAULT NULL,
    activity_ip INET DEFAULT NULL,
    activity_user_agent TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    activity_id UUID;
BEGIN
    INSERT INTO public.user_activity (
        user_id, activity_type, activity_description, metadata, ip_address, user_agent
    )
    VALUES (
        activity_user_id, activity_type, activity_description, 
        activity_metadata, activity_ip, activity_user_agent
    )
    RETURNING id INTO activity_id;
    
    -- Update last_login if it's a login activity
    IF activity_type = 'login' THEN
        UPDATE public.profiles 
        SET last_login = NOW(), login_count = login_count + 1
        WHERE id = activity_user_id;
    END IF;
    
    RETURN activity_id;
END;
$$ LANGUAGE plpgsql;

-- Create function to get recent activity for admin dashboard
CREATE OR REPLACE FUNCTION get_recent_activity(limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
    id UUID,
    user_name TEXT,
    user_email TEXT,
    activity_type TEXT,
    activity_description TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ua.id,
        p.full_name as user_name,
        p.email as user_email,
        ua.activity_type,
        ua.activity_description,
        ua.created_at,
        ua.metadata
    FROM public.user_activity ua
    JOIN public.profiles p ON ua.user_id = p.id
    ORDER BY ua.created_at DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Create function to check if user is super admin
CREATE OR REPLACE FUNCTION is_super_admin(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = user_id AND role = 'super_admin'
    );
END;
$$ LANGUAGE plpgsql;

-- Create function to check if user is admin or super admin
CREATE OR REPLACE FUNCTION is_admin_or_super_admin(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = user_id AND role IN ('admin', 'super_admin')
    );
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-approve products listed by admins
CREATE OR REPLACE FUNCTION auto_approve_admin_products()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if the product owner is an admin or super admin
    IF EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = NEW.owner_id AND role IN ('admin', 'super_admin')
    ) THEN
        NEW.status = 'approved';
        NEW.is_available = TRUE;
        NEW.listed_by_admin = TRUE;
        NEW.approved_by = NEW.owner_id;
        NEW.approved_at = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for auto-approval
DROP TRIGGER IF EXISTS trigger_auto_approve_admin_products ON public.products;
CREATE TRIGGER trigger_auto_approve_admin_products
    BEFORE INSERT ON public.products
    FOR EACH ROW
    EXECUTE FUNCTION auto_approve_admin_products();

-- Create view for user management
CREATE OR REPLACE VIEW admin_users_view AS
SELECT 
    p.*,
    COUNT(pr.id) as total_products,
    COUNT(o.id) as total_orders,
    MAX(ua.created_at) as last_activity,
    CASE 
        WHEN p.last_login > NOW() - INTERVAL '7 days' THEN 'active'
        WHEN p.last_login > NOW() - INTERVAL '30 days' THEN 'recent'
        ELSE 'inactive'
    END as activity_status
FROM public.profiles p
LEFT JOIN public.products pr ON p.id = pr.owner_id
LEFT JOIN public.orders o ON p.id = o.user_id
LEFT JOIN public.user_activity ua ON p.id = ua.user_id
WHERE p.role != 'super_admin' OR p.id = auth.uid() -- Super admins can see everyone, others see non-super-admins
GROUP BY p.id
ORDER BY p.created_at DESC;

-- Grant permissions on view
GRANT SELECT ON admin_users_view TO authenticated;

-- Update RLS policies for profiles to allow role management
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;

CREATE POLICY "Users can view their own profile" ON public.profiles
    FOR SELECT USING (id = auth.uid());

CREATE POLICY "Users can update their own profile" ON public.profiles
    FOR UPDATE USING (id = auth.uid());

CREATE POLICY "Admins can view all profiles" ON public.profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role IN ('admin', 'super_admin')
        )
    );

CREATE POLICY "Super admins can manage all profiles" ON public.profiles
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'super_admin'
        )
    );

-- Insert some sample recent activity
INSERT INTO public.user_activity (user_id, activity_type, activity_description, metadata)
SELECT 
    id,
    'login',
    'User logged into the system',
    jsonb_build_object('login_method', 'email')
FROM public.profiles 
WHERE role IN ('admin', 'super_admin')
LIMIT 5
ON CONFLICT DO NOTHING;

-- Create notification for schema update
INSERT INTO public.admin_notifications (type, title, message, priority) VALUES 
    ('system_alert', 'Database Schema Updated', 'Missing columns and functions have been added successfully.', 'high')
ON CONFLICT DO NOTHING;

COMMENT ON TABLE public.user_activity IS 'Tracks user activities for analytics and recent activity display';
COMMENT ON COLUMN public.profiles.role IS 'User role: user, admin, or super_admin';
COMMENT ON COLUMN public.profiles.listed_by_admin IS 'Whether the product was listed by an admin (auto-approved)';
COMMENT ON FUNCTION log_user_activity IS 'Logs user activity with optional metadata';
COMMENT ON FUNCTION get_recent_activity IS 'Gets recent user activities for admin dashboard';
COMMENT ON FUNCTION is_super_admin IS 'Checks if user is a super admin';
COMMENT ON FUNCTION is_admin_or_super_admin IS 'Checks if user is admin or super admin';
