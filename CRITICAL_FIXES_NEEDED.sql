-- ============================================================================
-- CRITICAL FIXES FOR RENTIMADE PLATFORM
-- ============================================================================
-- Run this in your Supabase SQL Editor to fix all issues
-- ============================================================================

-- ============================================================================
-- PART 1: CREATE BANNERS TABLES (Missing from database)
-- ============================================================================

-- 1. Banner Categories Table
CREATE TABLE IF NOT EXISTS public.banner_categories (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  name text NOT NULL UNIQUE,
  slug text NOT NULL UNIQUE,
  description text,
  display_order integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT banner_categories_pkey PRIMARY KEY (id)
);

-- 2. Banners Table
CREATE TABLE IF NOT EXISTS public.banners (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  title text NOT NULL,
  subtitle text,
  description text,
  image_url text NOT NULL,
  mobile_image_url text,
  link_url text,
  link_text text DEFAULT 'Shop Now',
  category_id uuid,
  display_order integer DEFAULT 0,
  is_active boolean DEFAULT true,
  start_date timestamp with time zone,
  end_date timestamp with time zone,
  target_blank boolean DEFAULT true,
  background_color text,
  text_color text,
  button_color text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  created_by uuid,
  CONSTRAINT banners_pkey PRIMARY KEY (id),
  CONSTRAINT banners_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.banner_categories(id) ON DELETE SET NULL,
  CONSTRAINT banners_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_banners_category_id ON public.banners(category_id);
CREATE INDEX IF NOT EXISTS idx_banners_is_active ON public.banners(is_active);
CREATE INDEX IF NOT EXISTS idx_banners_display_order ON public.banners(display_order);
CREATE INDEX IF NOT EXISTS idx_banner_categories_is_active ON public.banner_categories(is_active);
CREATE INDEX IF NOT EXISTS idx_banner_categories_slug ON public.banner_categories(slug);

-- ============================================================================
-- PART 2: BANNER RLS POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE public.banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.banner_categories ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "banners_select_policy" ON public.banners;
DROP POLICY IF EXISTS "banners_insert_policy" ON public.banners;
DROP POLICY IF EXISTS "banners_update_policy" ON public.banners;
DROP POLICY IF EXISTS "banners_delete_policy" ON public.banners;

DROP POLICY IF EXISTS "banner_categories_select_policy" ON public.banner_categories;
DROP POLICY IF EXISTS "banner_categories_insert_policy" ON public.banner_categories;
DROP POLICY IF EXISTS "banner_categories_update_policy" ON public.banner_categories;
DROP POLICY IF EXISTS "banner_categories_delete_policy" ON public.banner_categories;

-- Banners Policies
CREATE POLICY "banners_select_policy" ON public.banners
  FOR SELECT
  USING (true);  -- Everyone can view banners

CREATE POLICY "banners_insert_policy" ON public.banners
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND is_admin = true
    )
  );

CREATE POLICY "banners_update_policy" ON public.banners
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND is_admin = true
    )
  );

CREATE POLICY "banners_delete_policy" ON public.banners
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND is_admin = true
    )
  );

-- Banner Categories Policies
CREATE POLICY "banner_categories_select_policy" ON public.banner_categories
  FOR SELECT
  USING (true);  -- Everyone can view categories

CREATE POLICY "banner_categories_insert_policy" ON public.banner_categories
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND is_admin = true
    )
  );

CREATE POLICY "banner_categories_update_policy" ON public.banner_categories
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND is_admin = true
    )
  );

CREATE POLICY "banner_categories_delete_policy" ON public.banner_categories
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND is_admin = true
    )
  );

-- ============================================================================
-- PART 3: CREATE ADMIN_USERS_VIEW (Missing from database)
-- ============================================================================

-- Drop existing view if it exists
DROP VIEW IF EXISTS public.admin_users_view;

-- Create comprehensive admin users view
CREATE VIEW public.admin_users_view AS
SELECT 
  p.id,
  p.email,
  p.full_name,
  p.phone,
  p.city,
  p.state,
  p.pincode,
  p.avatar_url,
  CASE 
    WHEN p.is_admin THEN 'admin'::text
    ELSE 'user'::text
  END as role,
  true as is_active,  -- Default to true, add is_active column to profiles if needed
  p.is_admin,
  p.created_at,
  p.updated_at,
  au.last_sign_in_at as last_login,
  COALESCE((
    SELECT COUNT(*) 
    FROM auth.sessions s 
    WHERE s.user_id = p.id
  ), 0)::integer as login_count,
  COALESCE((
    SELECT COUNT(*) 
    FROM public.products pr 
    WHERE pr.owner_id = p.id
  ), 0)::integer as total_products,
  COALESCE((
    SELECT COUNT(*) 
    FROM public.orders o 
    WHERE o.user_id = p.id OR o.owner_id = p.id
  ), 0)::integer as total_orders,
  au.last_sign_in_at as last_activity,
  CASE 
    WHEN au.last_sign_in_at > NOW() - INTERVAL '1 day' THEN 'active'::text
    WHEN au.last_sign_in_at > NOW() - INTERVAL '7 days' THEN 'recent'::text
    ELSE 'inactive'::text
  END as activity_status,
  NULL::text as notes  -- Add notes column to profiles if needed
FROM public.profiles p
LEFT JOIN auth.users au ON au.id = p.id;

-- Grant access to authenticated users
GRANT SELECT ON public.admin_users_view TO authenticated;

-- ============================================================================
-- PART 4: ADD MISSING COLUMNS TO PROFILES TABLE
-- ============================================================================

-- Add is_active column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'profiles' 
    AND column_name = 'is_active'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN is_active boolean DEFAULT true;
  END IF;
END $$;

-- Add role column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'profiles' 
    AND column_name = 'role'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN role text DEFAULT 'user'::text CHECK (role = ANY (ARRAY['user'::text, 'admin'::text, 'super_admin'::text]));
  END IF;
END $$;

-- Add notes column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'profiles' 
    AND column_name = 'notes'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN notes text;
  END IF;
END $$;

-- Sync role with is_admin flag for existing users
UPDATE public.profiles 
SET role = CASE 
  WHEN is_admin = true THEN 'admin'::text 
  ELSE 'user'::text 
END
WHERE role IS NULL OR role = 'user';

-- ============================================================================
-- PART 5: INSERT DEFAULT BANNER CATEGORIES
-- ============================================================================

INSERT INTO public.banner_categories (name, slug, description, display_order, is_active)
VALUES 
  ('Home Hero', 'home-hero', 'Main hero banners on homepage', 1, true),
  ('Featured', 'featured', 'Featured product banners', 2, true),
  ('Seasonal', 'seasonal', 'Seasonal and event-based banners', 3, true),
  ('Promotions', 'promotions', 'Promotional and discount banners', 4, true),
  ('Categories', 'categories', 'Category highlight banners', 5, true)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================================
-- PART 6: CREATE BANNER TRIGGER FOR UPDATED_AT
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for banners
DROP TRIGGER IF EXISTS update_banners_updated_at ON public.banners;
CREATE TRIGGER update_banners_updated_at
  BEFORE UPDATE ON public.banners
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Trigger for banner_categories
DROP TRIGGER IF EXISTS update_banner_categories_updated_at ON public.banner_categories;
CREATE TRIGGER update_banner_categories_updated_at
  BEFORE UPDATE ON public.banner_categories
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- VERIFICATION QUERIES (Run these to check if everything is created)
-- ============================================================================

-- Check if banners table exists
SELECT 
  EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'banners'
  ) as banners_exists;

-- Check if banner_categories table exists
SELECT 
  EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'banner_categories'
  ) as banner_categories_exists;

-- Check if admin_users_view exists
SELECT 
  EXISTS (
    SELECT FROM information_schema.views 
    WHERE table_schema = 'public' 
    AND table_name = 'admin_users_view'
  ) as admin_users_view_exists;

-- Check profiles columns
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'profiles'
AND column_name IN ('is_active', 'role', 'notes')
ORDER BY column_name;

-- Count banner categories
SELECT COUNT(*) as banner_categories_count FROM public.banner_categories;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '✅ ALL CRITICAL FIXES APPLIED SUCCESSFULLY!';
  RAISE NOTICE '';
  RAISE NOTICE '1. ✅ Banners tables created (banners, banner_categories)';
  RAISE NOTICE '2. ✅ Banner RLS policies created';
  RAISE NOTICE '3. ✅ admin_users_view created';
  RAISE NOTICE '4. ✅ Profile columns added (is_active, role, notes)';
  RAISE NOTICE '5. ✅ Default banner categories inserted';
  RAISE NOTICE '6. ✅ Triggers created for updated_at';
  RAISE NOTICE '';
  RAISE NOTICE '🎉 Your database is now ready!';
  RAISE NOTICE 'Restart your Next.js dev server: npm run dev';
END $$;

