-- Migration: Add wallets support
-- Execute this in the Supabase SQL Editor

-- 1. Create wallets table
CREATE TABLE IF NOT EXISTS wallets (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('conta_corrente', 'poupanca', 'carteira', 'credito')),
  balance NUMERIC(12,2) DEFAULT 0,
  color TEXT DEFAULT '#6C63FF',
  icon TEXT DEFAULT 'account_balance_wallet',
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Add wallet_id to bills and incomes
ALTER TABLE bills ADD COLUMN IF NOT EXISTS wallet_id UUID REFERENCES wallets(id) ON DELETE SET NULL;
ALTER TABLE incomes ADD COLUMN IF NOT EXISTS wallet_id UUID REFERENCES wallets(id) ON DELETE SET NULL;

-- 3. Create indexes
CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON wallets(user_id);
CREATE INDEX IF NOT EXISTS idx_bills_wallet_id ON bills(wallet_id);
CREATE INDEX IF NOT EXISTS idx_incomes_wallet_id ON incomes(wallet_id);

-- 4. Enable RLS
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies
CREATE POLICY "Users can view own wallets"
  ON wallets FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own wallets"
  ON wallets FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own wallets"
  ON wallets FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own wallets"
  ON wallets FOR DELETE
  USING (auth.uid() = user_id);

-- 6. Trigger: ensure only one default wallet per user
CREATE OR REPLACE FUNCTION ensure_single_default_wallet()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_default = TRUE THEN
    UPDATE wallets SET is_default = FALSE WHERE user_id = NEW.user_id AND id != NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS single_default_wallet_trigger ON wallets;
CREATE TRIGGER single_default_wallet_trigger
  BEFORE INSERT OR UPDATE ON wallets
  FOR EACH ROW EXECUTE FUNCTION ensure_single_default_wallet();
