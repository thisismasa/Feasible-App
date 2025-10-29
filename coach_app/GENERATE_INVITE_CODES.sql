-- ============================================
-- Quick Script: Generate 5 Invite Codes
-- ============================================
-- Run this in Supabase SQL Editor to create invite codes for your friends

-- Generate 5 invite codes (valid for 30 days, 1 use each)
DO $$
DECLARE
  code1 TEXT;
  code2 TEXT;
  code3 TEXT;
  code4 TEXT;
  code5 TEXT;
BEGIN
  -- Generate codes
  SELECT generate_invite_code(1, 30, NULL, 'Friend 1') INTO code1;
  SELECT generate_invite_code(1, 30, NULL, 'Friend 2') INTO code2;
  SELECT generate_invite_code(1, 30, NULL, 'Friend 3') INTO code3;
  SELECT generate_invite_code(1, 30, NULL, 'Friend 4') INTO code4;
  SELECT generate_invite_code(1, 30, NULL, 'Friend 5') INTO code5;

  -- Display codes
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '  Your 5 Invite Codes (Share with Friends)';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Friend 1: %', 'https://tones-dancing-patches-searching.trycloudflare.com/?invite=' || code1;
  RAISE NOTICE 'Friend 2: %', 'https://tones-dancing-patches-searching.trycloudflare.com/?invite=' || code2;
  RAISE NOTICE 'Friend 3: %', 'https://tones-dancing-patches-searching.trycloudflare.com/?invite=' || code3;
  RAISE NOTICE 'Friend 4: %', 'https://tones-dancing-patches-searching.trycloudflare.com/?invite=' || code4;
  RAISE NOTICE 'Friend 5: %', 'https://tones-dancing-patches-searching.trycloudflare.com/?invite=' || code5;
  RAISE NOTICE '';
  RAISE NOTICE 'Each code:';
  RAISE NOTICE '  - Valid for 30 days';
  RAISE NOTICE '  - Can be used 1 time';
  RAISE NOTICE '  - Auto-approves user';
  RAISE NOTICE '';
  RAISE NOTICE 'Just copy and send these links to your friends!';
  RAISE NOTICE '========================================';
END $$;

-- View all active invite codes
SELECT
  code,
  'https://tones-dancing-patches-searching.trycloudflare.com/?invite=' || code as invite_link,
  max_uses,
  used_count,
  max_uses - used_count as remaining,
  expires_at,
  notes
FROM invite_codes
WHERE
  used_count < max_uses
  AND (expires_at IS NULL OR expires_at > NOW())
ORDER BY created_at DESC;
