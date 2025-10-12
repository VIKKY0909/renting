-- Banner Management Schema
-- This script creates tables and functions for managing banners in the admin panel

-- Create banners table
CREATE TABLE IF NOT EXISTS banners (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    subtitle VARCHAR(255),
    description TEXT,
    button_text VARCHAR(100),
    button_link VARCHAR(500),
    image_url TEXT NOT NULL,
    gradient_from VARCHAR(7) DEFAULT '#ff6b9d',
    gradient_to VARCHAR(7) DEFAULT '#c44569',
    gradient_via VARCHAR(7) DEFAULT '#f8b500',
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

-- Create banner_categories table for organizing banners
CREATE TABLE IF NOT EXISTS banner_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add category_id to banners table
ALTER TABLE banners ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES banner_categories(id) ON DELETE SET NULL;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_banners_active ON banners(is_active);
CREATE INDEX IF NOT EXISTS idx_banners_sort_order ON banners(sort_order);
CREATE INDEX IF NOT EXISTS idx_banners_category ON banners(category_id);
CREATE INDEX IF NOT EXISTS idx_banners_created_at ON banners(created_at);

-- Insert default banner categories
INSERT INTO banner_categories (name, description) VALUES 
    ('Homepage Hero', 'Main banner slides for homepage'),
    ('Promotional', 'Sales and promotional banners'),
    ('Seasonal', 'Seasonal and holiday banners'),
    ('Category', 'Category-specific banners')
ON CONFLICT (name) DO NOTHING;

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_banners_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
DROP TRIGGER IF EXISTS trigger_update_banners_updated_at ON banners;
CREATE TRIGGER trigger_update_banners_updated_at
    BEFORE UPDATE ON banners
    FOR EACH ROW
    EXECUTE FUNCTION update_banners_updated_at();

-- Enable Row Level Security
ALTER TABLE banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE banner_categories ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for banners
CREATE POLICY "Public can view active banners" ON banners
    FOR SELECT USING (is_active = true);

CREATE POLICY "Admin can manage banners" ON banners
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.is_admin = true
        )
    );

-- Create RLS policies for banner_categories
CREATE POLICY "Public can view active banner categories" ON banner_categories
    FOR SELECT USING (is_active = true);

CREATE POLICY "Admin can manage banner categories" ON banner_categories
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.is_admin = true
        )
    );

-- Create view for active banners with category info
CREATE OR REPLACE VIEW active_banners AS
SELECT 
    b.*,
    bc.name as category_name,
    bc.description as category_description
FROM banners b
LEFT JOIN banner_categories bc ON b.category_id = bc.id
WHERE b.is_active = true
ORDER BY b.sort_order ASC, b.created_at DESC;

-- Grant permissions
GRANT SELECT ON active_banners TO anon, authenticated;
GRANT ALL ON banners TO authenticated;
GRANT ALL ON banner_categories TO authenticated;

-- Insert sample banners (only if no banners exist)
INSERT INTO banners (
    title, 
    subtitle, 
    description, 
    button_text, 
    button_link, 
    image_url,
    gradient_from,
    gradient_to,
    gradient_via,
    category_id,
    sort_order
) 
SELECT 
    'New Collection',
    'Designer Dresses',
    'Discover our latest collection of stunning designer dresses for every occasion',
    'Shop Now',
    '/browse',
    'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=1200&h=600&fit=crop',
    '#ff6b9d',
    '#c44569',
    '#f8b500',
    (SELECT id FROM banner_categories WHERE name = 'Homepage Hero'),
    1
WHERE NOT EXISTS (SELECT 1 FROM banners LIMIT 1);

INSERT INTO banners (
    title, 
    subtitle, 
    description, 
    button_text, 
    button_link, 
    image_url,
    gradient_from,
    gradient_to,
    gradient_via,
    category_id,
    sort_order
) 
SELECT 
    'Summer Sale',
    'Up to 50% Off',
    'Get ready for summer with our exclusive collection at unbeatable prices',
    'View Sale',
    '/browse?sale=true',
    'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=1200&h=600&fit=crop',
    '#c44569',
    '#f8b500',
    '#ff6b9d',
    (SELECT id FROM banner_categories WHERE name = 'Promotional'),
    2
WHERE NOT EXISTS (SELECT 1 FROM banners WHERE title = 'Summer Sale');

INSERT INTO banners (
    title, 
    subtitle, 
    description, 
    button_text, 
    button_link, 
    image_url,
    gradient_from,
    gradient_to,
    gradient_via,
    category_id,
    sort_order
) 
SELECT 
    'Bridal Collection',
    'Dream Wedding',
    'Make your special day unforgettable with our exquisite bridal collection',
    'Explore',
    '/browse?category=bridal',
    'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=1200&h=600&fit=crop',
    '#f8b500',
    '#ff6b9d',
    '#c44569',
    (SELECT id FROM banner_categories WHERE name = 'Homepage Hero'),
    3
WHERE NOT EXISTS (SELECT 1 FROM banners WHERE title = 'Bridal Collection');

-- Create function to get banners by category
CREATE OR REPLACE FUNCTION get_banners_by_category(category_name TEXT DEFAULT NULL)
RETURNS TABLE (
    id UUID,
    title VARCHAR(255),
    subtitle VARCHAR(255),
    description TEXT,
    button_text VARCHAR(100),
    button_link VARCHAR(500),
    image_url TEXT,
    gradient_from VARCHAR(7),
    gradient_to VARCHAR(7),
    gradient_via VARCHAR(7),
    sort_order INTEGER,
    category_name VARCHAR(100)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.id,
        b.title,
        b.subtitle,
        b.description,
        b.button_text,
        b.button_link,
        b.image_url,
        b.gradient_from,
        b.gradient_to,
        b.gradient_via,
        b.sort_order,
        bc.name as category_name
    FROM banners b
    LEFT JOIN banner_categories bc ON b.category_id = bc.id
    WHERE b.is_active = true
    AND (category_name IS NULL OR bc.name = category_name)
    ORDER BY b.sort_order ASC, b.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION get_banners_by_category(TEXT) TO anon, authenticated;




