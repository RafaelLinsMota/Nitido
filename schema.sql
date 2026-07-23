-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- Users table
-- ============================================
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  USING (auth.uid() = id);

-- ============================================
-- Categories table
-- ============================================
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  icon TEXT NOT NULL,
  color TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Categories are viewable"
  ON categories FOR SELECT
  USING (user_id IS NULL OR user_id = auth.uid());

CREATE POLICY "Users can create categories"
  ON categories FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own categories"
  ON categories FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "Users can delete own categories"
  ON categories FOR DELETE
  USING (user_id = auth.uid());

INSERT INTO categories (id, name, icon, color) VALUES
  ('550e8400-e29b-41d4-a716-446655440001', 'Moradia', 'home', '#A78BFA'),
  ('550e8400-e29b-41d4-a716-446655440002', 'Alimentação', 'restaurant', '#FB923C'),
  ('550e8400-e29b-41d4-a716-446655440003', 'Transporte', 'directions_car', '#38BDF8'),
  ('550e8400-e29b-41d4-a716-446655440004', 'Lazer', 'sports_esports', '#F472B6'),
  ('550e8400-e29b-41d4-a716-446655440005', 'Saúde', 'favorite', '#94A3B8'),
  ('550e8400-e29b-41d4-a716-446655440006', 'Energia', 'bolt', '#38BDF8'),
  ('550e8400-e29b-41d4-a716-446655440007', 'Cartão de crédito', 'credit_card', '#F472B6'),
  ('550e8400-e29b-41d4-a716-446655440008', 'Outros', 'more_horiz', '#94A3B8');

-- ============================================
-- Incomes table
-- ============================================
CREATE TABLE incomes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  amount NUMERIC(10,2) NOT NULL,
  recurring BOOLEAN DEFAULT FALSE,
  recurrence_day INTEGER,
  received_at DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE incomes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own incomes"
  ON incomes FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can create incomes"
  ON incomes FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own incomes"
  ON incomes FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "Users can delete own incomes"
  ON incomes FOR DELETE
  USING (user_id = auth.uid());

-- ============================================
-- Bills table
-- ============================================
CREATE TABLE bills (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES categories(id),
  title TEXT NOT NULL,
  amount NUMERIC(10,2) NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('fixa', 'variavel', 'parcelada')),
  due_date DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente', 'paga', 'atrasada')),
  installment_current INTEGER,
  installment_total INTEGER,
  group_id UUID,
  paid_at DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE bills ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own bills"
  ON bills FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can create bills"
  ON bills FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own bills"
  ON bills FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "Users can delete own bills"
  ON bills FOR DELETE
  USING (user_id = auth.uid());

CREATE INDEX idx_bills_user_id ON bills(user_id);
CREATE INDEX idx_bills_due_date ON bills(due_date);
CREATE INDEX idx_bills_status ON bills(status);
CREATE INDEX idx_bills_group_id ON bills(group_id);
CREATE INDEX idx_incomes_user_id ON incomes(user_id);
CREATE INDEX idx_categories_user_id ON categories(user_id);

-- Function to auto-update overdue bills
CREATE OR REPLACE FUNCTION update_overdue_bills()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE bills
  SET status = 'atrasada'
  WHERE status = 'pendente'
    AND due_date < CURRENT_DATE;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_overdue_bills
  AFTER INSERT ON bills
  FOR EACH STATEMENT
  EXECUTE FUNCTION update_overdue_bills();

-- Function to handle new user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO users (id, name, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', 'Usuário'),
    NEW.email
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();
