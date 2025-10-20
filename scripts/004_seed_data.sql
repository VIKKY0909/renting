-- Insert default categories
INSERT INTO public.categories (name, slug, description, image_url) VALUES
  ('Lehenga', 'lehenga', 'Traditional Indian bridal and festive lehengas', '/traditional-indian-lehenga.jpg'),
  ('Saree', 'saree', 'Elegant sarees for all occasions', '/designer-silk-saree.jpg'),
  ('Gown', 'gown', 'Designer gowns and evening wear', '/elegant-designer-gown.jpg'),
  ('Indo-Western', 'indo-western', 'Fusion wear combining Indian and Western styles', '/indo-western-outfit.jpg')
ON CONFLICT (slug) DO NOTHING;

-- Insert sample FAQs
INSERT INTO public.faqs (question, answer, category, order_index, is_published) VALUES
  ('How does renting work?', 'Browse our collection, select your desired outfit, choose rental dates, and place your order. We deliver it to your doorstep, and you return it after your event.', 'General', 1, true),
  ('What is the rental period?', 'Standard rental period is 4-7 days. You can extend the rental period for an additional fee.', 'General', 2, true),
  ('How do I return the outfit?', 'We provide a prepaid return label. Simply pack the outfit and schedule a pickup or drop it at the nearest courier location.', 'Returns', 3, true),
  ('What if the outfit doesn''t fit?', 'We provide detailed size charts. If there''s an issue, contact us within 24 hours of delivery for a replacement (subject to availability).', 'Sizing', 4, true),
  ('Is dry cleaning included?', 'Yes! All outfits are professionally dry-cleaned before and after each rental at no extra cost.', 'General', 5, true),
  ('What is the security deposit?', 'A refundable security deposit is charged to cover any damages. It''s refunded within 7-10 days after the outfit is returned in good condition.', 'Payment', 6, true),
  ('Can I list my own outfits?', 'Yes! Click on "Lend Your Dress" to list your designer outfits and earn money when others rent them.', 'Lending', 7, true),
  ('How do I get paid as a lender?', 'Earnings are credited to your account after each successful rental. You can withdraw funds to your bank account anytime.', 'Lending', 8, true)
ON CONFLICT DO NOTHING;
