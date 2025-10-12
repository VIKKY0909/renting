-- =====================================================
-- ADD USER ADDRESSES SYSTEM
-- This script adds user address management functionality
-- =====================================================

-- Create user_addresses table
CREATE TABLE IF NOT EXISTS public.user_addresses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  address_type TEXT NOT NULL DEFAULT 'home' CHECK (address_type IN ('home', 'work', 'other')),
  is_default BOOLEAN DEFAULT FALSE,
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  address_line_1 TEXT NOT NULL,
  address_line_2 TEXT,
  city TEXT NOT NULL,
  state TEXT NOT NULL,
  pincode TEXT NOT NULL,
  landmark TEXT,
  instructions TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure only one default address per user
  CONSTRAINT unique_default_address UNIQUE (user_id, is_default) DEFERRABLE INITIALLY DEFERRED
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_addresses_user_id ON public.user_addresses(user_id);
CREATE INDEX IF NOT EXISTS idx_user_addresses_default ON public.user_addresses(user_id, is_default) WHERE is_default = TRUE;

-- Add trigger for updated_at
CREATE TRIGGER update_user_addresses_updated_at 
  BEFORE UPDATE ON public.user_addresses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to ensure only one default address per user
CREATE OR REPLACE FUNCTION ensure_single_default_address()
RETURNS TRIGGER AS $$
BEGIN
  -- If setting a new default address, unset all other default addresses for this user
  IF NEW.is_default = TRUE THEN
    UPDATE public.user_addresses 
    SET is_default = FALSE 
    WHERE user_id = NEW.user_id 
    AND id != NEW.id 
    AND is_default = TRUE;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to ensure single default address
CREATE TRIGGER trigger_ensure_single_default_address
  BEFORE INSERT OR UPDATE ON public.user_addresses
  FOR EACH ROW EXECUTE FUNCTION ensure_single_default_address();

-- Enable Row Level Security
ALTER TABLE public.user_addresses ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own addresses" ON public.user_addresses
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own addresses" ON public.user_addresses
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own addresses" ON public.user_addresses
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own addresses" ON public.user_addresses
  FOR DELETE USING (auth.uid() = user_id);

-- Add comments for documentation
COMMENT ON TABLE public.user_addresses IS 'User address management for delivery and pickup';
COMMENT ON COLUMN public.user_addresses.address_type IS 'Type of address: home, work, or other';
COMMENT ON COLUMN public.user_addresses.is_default IS 'Whether this is the default address for the user';
COMMENT ON COLUMN public.user_addresses.landmark IS 'Optional landmark for easy location';
COMMENT ON COLUMN public.user_addresses.instructions IS 'Special delivery instructions';

-- Verify the table was created successfully
SELECT 
    table_name, 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_addresses' 
AND table_schema = 'public'
ORDER BY ordinal_position;
