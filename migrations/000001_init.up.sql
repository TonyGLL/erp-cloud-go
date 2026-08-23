-- ============================================================
-- ERP Cloud - Initial Database Schema
-- File: init.up.sql
-- ============================================================

BEGIN;

-- ============================================================
-- Extensions
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- Utility: updated_at trigger
-- ============================================================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Roles
-- ============================================================

CREATE TABLE roles (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Users
-- ============================================================

CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    role_id BIGINT NOT NULL REFERENCES roles(id),
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE passwords (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id),
  hash TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_role_id
    ON users(role_id);

CREATE INDEX idx_users_active
    ON users(active);

CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- Categories
-- ============================================================

CREATE TABLE categories (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_categories_active
    ON categories(active);

CREATE TRIGGER trg_categories_updated_at
BEFORE UPDATE ON categories
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- Customers
-- ============================================================

CREATE TABLE customers (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(50),
    tax_id VARCHAR(50),
    address TEXT,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_customers_email
    ON customers(email);

CREATE INDEX idx_customers_tax_id
    ON customers(tax_id);

CREATE INDEX idx_customers_active
    ON customers(active);

CREATE TRIGGER trg_customers_updated_at
BEFORE UPDATE ON customers
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- Suppliers
-- ============================================================

CREATE TABLE suppliers (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(50),
    tax_id VARCHAR(50),
    address TEXT,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_suppliers_email
    ON suppliers(email);

CREATE INDEX idx_suppliers_tax_id
    ON suppliers(tax_id);

CREATE INDEX idx_suppliers_active
    ON suppliers(active);

CREATE TRIGGER trg_suppliers_updated_at
BEFORE UPDATE ON suppliers
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- Warehouses
-- ============================================================

CREATE TABLE warehouses (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    address TEXT,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_warehouses_active
    ON warehouses(active);

CREATE TRIGGER trg_warehouses_updated_at
BEFORE UPDATE ON warehouses
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- Products
-- ============================================================

CREATE TABLE products (
    id BIGSERIAL PRIMARY KEY,
    sku VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    category_id BIGINT NOT NULL REFERENCES categories(id),
    supplier_id BIGINT REFERENCES suppliers(id),
    cost NUMERIC(12, 2) NOT NULL DEFAULT 0,
    price NUMERIC(12, 2) NOT NULL,
    tax_rate NUMERIC(5, 2) NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_products_cost_non_negative
        CHECK (cost >= 0),

    CONSTRAINT chk_products_price_positive
        CHECK (price > 0),

    CONSTRAINT chk_products_price_gte_cost
        CHECK (price >= cost),

    CONSTRAINT chk_products_tax_rate
        CHECK (tax_rate >= 0 AND tax_rate <= 100)
);

CREATE INDEX idx_products_category_id
    ON products(category_id);

CREATE INDEX idx_products_supplier_id
    ON products(supplier_id);

CREATE INDEX idx_products_active
    ON products(active);

CREATE INDEX idx_products_name
    ON products(name);

CREATE TRIGGER trg_products_updated_at
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- Inventory
-- ============================================================

CREATE TABLE inventory (
    product_id BIGINT NOT NULL REFERENCES products(id),
    warehouse_id BIGINT NOT NULL REFERENCES warehouses(id),

    quantity INTEGER NOT NULL DEFAULT 0,
    reserved_quantity INTEGER NOT NULL DEFAULT 0,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (product_id, warehouse_id),

    CONSTRAINT chk_inventory_quantity
        CHECK (quantity >= 0),

    CONSTRAINT chk_inventory_reserved_quantity
        CHECK (reserved_quantity >= 0),

    CONSTRAINT chk_inventory_reserved_lte_quantity
        CHECK (reserved_quantity <= quantity)
);

CREATE INDEX idx_inventory_warehouse_id
    ON inventory(warehouse_id);

-- ============================================================
-- Inventory Movements
-- ============================================================

CREATE TYPE inventory_movement_type AS ENUM (
    'PURCHASE',
    'SALE',
    'ADJUSTMENT',
    'TRANSFER_IN',
    'TRANSFER_OUT',
    'RETURN'
);

CREATE TABLE inventory_movements (
    id BIGSERIAL PRIMARY KEY,

    product_id BIGINT NOT NULL REFERENCES products(id),
    warehouse_id BIGINT NOT NULL REFERENCES warehouses(id),

    type inventory_movement_type NOT NULL,

    quantity INTEGER NOT NULL,

    reference_type VARCHAR(50),
    reference_id BIGINT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_inventory_movements_quantity
        CHECK (quantity > 0)
);

CREATE INDEX idx_inventory_movements_product
    ON inventory_movements(product_id);

CREATE INDEX idx_inventory_movements_warehouse
    ON inventory_movements(warehouse_id);

CREATE INDEX idx_inventory_movements_created_at
    ON inventory_movements(created_at);

CREATE INDEX idx_inventory_movements_reference
    ON inventory_movements(reference_type, reference_id);

-- ============================================================
-- Purchases
-- ============================================================

CREATE TYPE purchase_status AS ENUM (
    'DRAFT',
    'RECEIVED',
    'CANCELLED'
);

CREATE TABLE purchases (
    id BIGSERIAL PRIMARY KEY,

    supplier_id BIGINT NOT NULL REFERENCES suppliers(id),
    warehouse_id BIGINT NOT NULL REFERENCES warehouses(id),

    status purchase_status NOT NULL DEFAULT 'DRAFT',

    subtotal NUMERIC(14, 2) NOT NULL DEFAULT 0,
    tax NUMERIC(14, 2) NOT NULL DEFAULT 0,
    total NUMERIC(14, 2) NOT NULL DEFAULT 0,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_purchases_subtotal
        CHECK (subtotal >= 0),

    CONSTRAINT chk_purchases_tax
        CHECK (tax >= 0),

    CONSTRAINT chk_purchases_total
        CHECK (total >= 0)
);

CREATE INDEX idx_purchases_supplier_id
    ON purchases(supplier_id);

CREATE INDEX idx_purchases_warehouse_id
    ON purchases(warehouse_id);

CREATE INDEX idx_purchases_status
    ON purchases(status);

CREATE INDEX idx_purchases_created_at
    ON purchases(created_at);

CREATE TRIGGER trg_purchases_updated_at
BEFORE UPDATE ON purchases
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- Purchase Items
-- ============================================================

CREATE TABLE purchase_items (
    id BIGSERIAL PRIMARY KEY,

    purchase_id BIGINT NOT NULL
        REFERENCES purchases(id)
        ON DELETE CASCADE,

    product_id BIGINT NOT NULL
        REFERENCES products(id),

    quantity INTEGER NOT NULL,
    unit_cost NUMERIC(12, 2) NOT NULL,
    subtotal NUMERIC(14, 2) NOT NULL,

    CONSTRAINT chk_purchase_items_quantity
        CHECK (quantity > 0),

    CONSTRAINT chk_purchase_items_unit_cost
        CHECK (unit_cost >= 0),

    CONSTRAINT chk_purchase_items_subtotal
        CHECK (subtotal >= 0)
);

CREATE INDEX idx_purchase_items_purchase_id
    ON purchase_items(purchase_id);

CREATE INDEX idx_purchase_items_product_id
    ON purchase_items(product_id);

-- ============================================================
-- Sales
-- ============================================================

CREATE TYPE sale_status AS ENUM (
    'DRAFT',
    'CONFIRMED',
    'COMPLETED',
    'CANCELLED'
);

CREATE TABLE sales (
    id BIGSERIAL PRIMARY KEY,

    customer_id BIGINT REFERENCES customers(id),
    warehouse_id BIGINT NOT NULL REFERENCES warehouses(id),

    status sale_status NOT NULL DEFAULT 'DRAFT',

    subtotal NUMERIC(14, 2) NOT NULL DEFAULT 0,
    tax NUMERIC(14, 2) NOT NULL DEFAULT 0,
    total NUMERIC(14, 2) NOT NULL DEFAULT 0,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_sales_subtotal
        CHECK (subtotal >= 0),

    CONSTRAINT chk_sales_tax
        CHECK (tax >= 0),

    CONSTRAINT chk_sales_total
        CHECK (total >= 0)
);

CREATE INDEX idx_sales_customer_id
    ON sales(customer_id);

CREATE INDEX idx_sales_warehouse_id
    ON sales(warehouse_id);

CREATE INDEX idx_sales_status
    ON sales(status);

CREATE INDEX idx_sales_created_at
    ON sales(created_at);

CREATE TRIGGER trg_sales_updated_at
BEFORE UPDATE ON sales
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- Sale Items
-- ============================================================

CREATE TABLE sale_items (
    id BIGSERIAL PRIMARY KEY,

    sale_id BIGINT NOT NULL
        REFERENCES sales(id)
        ON DELETE CASCADE,

    product_id BIGINT NOT NULL
        REFERENCES products(id),

    quantity INTEGER NOT NULL,
    unit_price NUMERIC(12, 2) NOT NULL,
    subtotal NUMERIC(14, 2) NOT NULL,

    CONSTRAINT chk_sale_items_quantity
        CHECK (quantity > 0),

    CONSTRAINT chk_sale_items_unit_price
        CHECK (unit_price > 0),

    CONSTRAINT chk_sale_items_subtotal
        CHECK (subtotal >= 0)
);

CREATE INDEX idx_sale_items_sale_id
    ON sale_items(sale_id);

CREATE INDEX idx_sale_items_product_id
    ON sale_items(product_id);

-- ============================================================
-- Seed Roles
-- ============================================================

INSERT INTO roles (name, description)
VALUES
    ('ADMIN', 'Full system access'),
    ('MANAGER', 'Management access'),
    ('WAREHOUSE', 'Warehouse and inventory access'),
    ('SALES', 'Sales and customer access')
ON CONFLICT (name) DO NOTHING;

COMMIT;
