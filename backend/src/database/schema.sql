-- Create UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Branches Table
CREATE TABLE IF NOT EXISTS branches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Users Table (Staff & Admins)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('ADMIN', 'EMPLOYEE')),
    branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Customers Table
CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(50) NOT NULL,
    age INT NOT NULL CHECK (age >= 0),
    gender VARCHAR(20) NOT NULL CHECK (gender IN ('MALE', 'FEMALE', 'OTHER')),
    medical_notes TEXT,
    chronic_diseases TEXT,
    blood_pressure_status VARCHAR(100),
    previous_hijama_history TEXT,
    notes TEXT,
    branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Loyalty Table
CREATE TABLE IF NOT EXISTS loyalty (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID UNIQUE REFERENCES customers(id) ON DELETE CASCADE,
    session_count INT DEFAULT 0 CHECK (session_count >= 0),
    discount_pct DECIMAL(5,2) DEFAULT 0.00 CHECK (discount_pct >= 0 AND discount_pct <= 100.00)
);

-- 5. Inventory Items Table
CREATE TABLE IF NOT EXISTS inventory_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    quantity INT DEFAULT 0 CHECK (quantity >= 0),
    purchase_price DECIMAL(10,2) NOT NULL CHECK (purchase_price >= 0),
    supplier VARCHAR(255),
    min_threshold INT DEFAULT 10 CHECK (min_threshold >= 0),
    branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 6. Purchases Table (Stock Restocks)
CREATE TABLE IF NOT EXISTS purchases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    inventory_item_id UUID REFERENCES inventory_items(id) ON DELETE CASCADE,
    quantity INT NOT NULL CHECK (quantity > 0),
    total_cost DECIMAL(10,2) NOT NULL CHECK (total_cost >= 0),
    supplier VARCHAR(255) NOT NULL,
    invoice_number VARCHAR(100),
    date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 7. Expenses Table (Operating Costs)
CREATE TABLE IF NOT EXISTS expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category VARCHAR(255) NOT NULL,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    description TEXT,
    date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    branch_id UUID REFERENCES branches(id) ON DELETE SET NULL
);

-- 8. Sessions Table (Treatments)
CREATE TABLE IF NOT EXISTS sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    session_type VARCHAR(100) NOT NULL CHECK (session_type IN ('DRY_CUPPING', 'WET_CUPPING', 'MASSAGE', 'RELAXATION', 'OTHER')),
    price_paid DECIMAL(10,2) NOT NULL CHECK (price_paid >= 0),
    total_cost DECIMAL(10,2) NOT NULL DEFAULT 0.0 CHECK (total_cost >= 0),
    debt_amount DECIMAL(10,2) NOT NULL DEFAULT 0.0 CHECK (debt_amount >= 0),
    cups_used INT DEFAULT 0 CHECK (cups_used >= 0),
    notes TEXT,
    date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 9. Session Materials Table (Consumables tracking)
CREATE TABLE IF NOT EXISTS session_materials (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
    inventory_item_id UUID REFERENCES inventory_items(id) ON DELETE CASCADE,
    quantity_used INT NOT NULL CHECK (quantity_used > 0)
);

-- 10. Appointments Table
CREATE TABLE IF NOT EXISTS appointments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    session_type VARCHAR(100) NOT NULL,
    scheduled_at TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(50) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'COMPLETED', 'CANCELLED')),
    notes TEXT
);

-- INDEXES for Search performance
CREATE INDEX IF NOT EXISTS idx_customers_name ON customers (full_name);
CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers (phone);
CREATE INDEX IF NOT EXISTS idx_sessions_date ON sessions (date);
CREATE INDEX IF NOT EXISTS idx_appointments_schedule ON appointments (scheduled_at);
CREATE INDEX IF NOT EXISTS idx_inventory_name ON inventory_items (name);
