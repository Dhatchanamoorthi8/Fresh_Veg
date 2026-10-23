-- ============================================================================
-- KISANFRESH MULTI-BRANCH VEGETABLE SHOPPING PLATFORM
-- Migration: 001_initial_grocery_schema
-- Description: Core schema, tables, RLS policies, transactional RPCs, and seed data.
-- ============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. HELPER FUNCTIONS FOR TIMESTAMPS
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. PROFILES TABLE (Linked to auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    phone TEXT UNIQUE,
    full_name TEXT,
    email TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER update_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 4. USER ROLES TABLE
CREATE TABLE IF NOT EXISTS public.user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('super_admin', 'branch_admin', 'branch_staff', 'delivery_staff', 'customer')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT user_roles_unique UNIQUE (user_id, role)
);

CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON public.user_roles(user_id);

-- 5. BRANCHES TABLE (At least 6 physical stores)
CREATE TABLE IF NOT EXISTS public.branches (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    area TEXT NOT NULL,
    address TEXT NOT NULL,
    phone TEXT NOT NULL,
    opening_hours TEXT NOT NULL,
    delivery_coverage TEXT NOT NULL,
    estimated_delivery_minutes INT NOT NULL DEFAULT 30,
    min_order_amount_paise INT NOT NULL DEFAULT 9900,
    free_delivery_threshold_paise INT NOT NULL DEFAULT 24900,
    standard_delivery_fee_paise INT NOT NULL DEFAULT 2900,
    is_open BOOLEAN NOT NULL DEFAULT true,
    is_accepting_orders BOOLEAN NOT NULL DEFAULT true,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER update_branches_updated_at
BEFORE UPDATE ON public.branches
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 6. BRANCH STAFF ASSIGNMENT TABLE
CREATE TABLE IF NOT EXISTS public.branch_staff (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    branch_id TEXT NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'branch_staff' CHECK (role IN ('branch_admin', 'branch_staff')),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT branch_staff_unique UNIQUE (user_id, branch_id)
);

CREATE INDEX IF NOT EXISTS idx_branch_staff_user ON public.branch_staff(user_id);
CREATE INDEX IF NOT EXISTS idx_branch_staff_branch ON public.branch_staff(branch_id);

-- 7. CUSTOMER ADDRESSES TABLE
CREATE TABLE IF NOT EXISTS public.customer_addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL, -- 'Home', 'Work', 'Other'
    full_address TEXT NOT NULL,
    landmark TEXT,
    area TEXT NOT NULL,
    pincode TEXT NOT NULL,
    phone TEXT,
    is_default BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_customer_addresses_user ON public.customer_addresses(user_id);

CREATE TRIGGER update_customer_addresses_updated_at
BEFORE UPDATE ON public.customer_addresses
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 8. PRODUCT CATEGORIES TABLE
CREATE TABLE IF NOT EXISTS public.categories (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    local_name TEXT NOT NULL,
    icon_name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    sort_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 9. PRODUCTS TABLE (Global Shared Catalogue)
CREATE TABLE IF NOT EXISTS public.products (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    local_name TEXT NOT NULL,
    category_id TEXT NOT NULL REFERENCES public.categories(id) ON DELETE RESTRICT,
    unit TEXT NOT NULL,
    description TEXT NOT NULL,
    storage_tips TEXT NOT NULL,
    origin TEXT NOT NULL,
    image_url TEXT,
    emoji TEXT NOT NULL DEFAULT '🥗',
    is_organic BOOLEAN NOT NULL DEFAULT false,
    is_seasonal BOOLEAN NOT NULL DEFAULT false,
    is_bestseller BOOLEAN NOT NULL DEFAULT false,
    is_active BOOLEAN NOT NULL DEFAULT true,
    base_price_paise INT NOT NULL CHECK (base_price_paise >= 0),
    original_price_paise INT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_active ON public.products(is_active);

CREATE TRIGGER update_products_updated_at
BEFORE UPDATE ON public.products
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 10. BRANCH INVENTORY & PRICING TABLE (Branch-specific stock & price overrides)
CREATE TABLE IF NOT EXISTS public.branch_inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id TEXT NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    product_id TEXT NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    price_paise INT, -- Nullable override; falls back to product.base_price_paise
    stock_quantity INT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    low_stock_threshold INT NOT NULL DEFAULT 5,
    is_available BOOLEAN NOT NULL DEFAULT true,
    is_active BOOLEAN NOT NULL DEFAULT true,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT branch_inventory_unique UNIQUE (branch_id, product_id)
);

CREATE INDEX IF NOT EXISTS idx_branch_inventory_branch ON public.branch_inventory(branch_id);
CREATE INDEX IF NOT EXISTS idx_branch_inventory_product ON public.branch_inventory(product_id);

CREATE TRIGGER update_branch_inventory_updated_at
BEFORE UPDATE ON public.branch_inventory
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 11. PROMOTIONS TABLE
CREATE TABLE IF NOT EXISTS public.promotions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT NOT NULL UNIQUE,
    title TEXT NOT NULL,
    description TEXT,
    discount_type TEXT NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
    discount_value INT NOT NULL CHECK (discount_value > 0),
    min_order_amount_paise INT NOT NULL DEFAULT 0,
    max_discount_paise INT,
    branch_id TEXT REFERENCES public.branches(id) ON DELETE CASCADE,
    start_time TIMESTAMPTZ NOT NULL DEFAULT now(),
    end_time TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_promotions_code ON public.promotions(code);

-- 12. PROMOTION PRODUCTS TABLE (For product-specific deals)
CREATE TABLE IF NOT EXISTS public.promotion_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    promotion_id UUID NOT NULL REFERENCES public.promotions(id) ON DELETE CASCADE,
    product_id TEXT NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT promotion_products_unique UNIQUE (promotion_id, product_id)
);

-- 13. CARTS TABLE (One active cart per user, linked to one branch)
CREATE TABLE IF NOT EXISTS public.carts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    branch_id TEXT REFERENCES public.branches(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER update_carts_updated_at
BEFORE UPDATE ON public.carts
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 14. CART ITEMS TABLE
CREATE TABLE IF NOT EXISTS public.cart_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cart_id UUID NOT NULL REFERENCES public.carts(id) ON DELETE CASCADE,
    product_id TEXT NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    quantity INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT cart_items_unique UNIQUE (cart_id, product_id)
);

CREATE TRIGGER update_cart_items_updated_at
BEFORE UPDATE ON public.cart_items
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 15. ORDERS TABLE
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number TEXT NOT NULL UNIQUE,
    customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    branch_id TEXT NOT NULL REFERENCES public.branches(id) ON DELETE RESTRICT,
    delivery_address_id UUID REFERENCES public.customer_addresses(id) ON DELETE SET NULL,
    customer_name TEXT NOT NULL,
    customer_phone TEXT NOT NULL,
    delivery_address_text TEXT NOT NULL,
    subtotal_paise INT NOT NULL CHECK (subtotal_paise >= 0),
    delivery_fee_paise INT NOT NULL CHECK (delivery_fee_paise >= 0),
    discount_paise INT NOT NULL DEFAULT 0 CHECK (discount_paise >= 0),
    total_paise INT NOT NULL CHECK (total_paise >= 0),
    status TEXT NOT NULL DEFAULT 'NEW' CHECK (
        status IN ('NEW', 'ACCEPTED', 'PREPARING', 'READY_FOR_PICKUP', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED', 'REJECTED')
    ),
    rejection_reason TEXT,
    payment_method TEXT NOT NULL,
    payment_status TEXT NOT NULL DEFAULT 'PENDING' CHECK (payment_status IN ('PENDING', 'PAID', 'FAILED', 'REFUNDED')),
    delivery_slot TEXT NOT NULL,
    delivery_instructions TEXT,
    assigned_delivery_staff_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    idempotency_key TEXT UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_orders_customer ON public.orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_branch ON public.orders(branch_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_delivery_staff ON public.orders(assigned_delivery_staff_id);

CREATE TRIGGER update_orders_updated_at
BEFORE UPDATE ON public.orders
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 16. ORDER ITEMS TABLE
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id TEXT NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
    product_name TEXT NOT NULL,
    unit TEXT NOT NULL,
    price_paise INT NOT NULL CHECK (price_paise >= 0),
    quantity INT NOT NULL CHECK (quantity > 0),
    total_paise INT NOT NULL CHECK (total_paise >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_order_items_order ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product ON public.order_items(product_id);

-- 17. DELIVERY ASSIGNMENTS TABLE
CREATE TABLE IF NOT EXISTS public.delivery_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    delivery_staff_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    assigned_by UUID REFERENCES public.profiles(id),
    status TEXT NOT NULL DEFAULT 'ASSIGNED' CHECK (status IN ('ASSIGNED', 'PICKED_UP', 'DELIVERED', 'CANCELLED')),
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ,
    notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_delivery_assignments_staff ON public.delivery_assignments(delivery_staff_id);
CREATE INDEX IF NOT EXISTS idx_delivery_assignments_order ON public.delivery_assignments(order_id);

-- 18. ORDER STATUS HISTORY TABLE (Complete Audit Trail)
CREATE TABLE IF NOT EXISTS public.order_status_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    status TEXT NOT NULL,
    notes TEXT,
    changed_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_order_status_history_order ON public.order_status_history(order_id);

-- 19. PAYMENTS TABLE
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    amount_paise INT NOT NULL CHECK (amount_paise >= 0),
    payment_method TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'SUCCESS', 'FAILED', 'REFUNDED')),
    transaction_ref TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 20. NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id);

-- ============================================================================
-- 21. AUTH USER PROFILE AUTOMATION TRIGGER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, phone, full_name, email, avatar_url)
    VALUES (
        NEW.id,
        NEW.phone,
        COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
        NEW.email,
        NEW.raw_user_meta_data->>'avatar_url'
    )
    ON CONFLICT (id) DO UPDATE SET
        phone = EXCLUDED.phone,
        email = EXCLUDED.email;

    -- Assign default customer role if no role exists
    INSERT INTO public.user_roles (user_id, role)
    VALUES (NEW.id, 'customer')
    ON CONFLICT (user_id, role) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- 22. SECURITY & ROLE HELPER FUNCTIONS
-- ============================================================================
CREATE OR REPLACE FUNCTION public.is_admin(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.user_roles
        WHERE user_id = p_user_id AND role IN ('super_admin', 'branch_admin')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_branch_staff(p_user_id UUID, p_branch_id TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.branch_staff
        WHERE user_id = p_user_id AND branch_id = p_branch_id AND is_active = true
    ) OR public.is_admin(p_user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_delivery_staff(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.user_roles
        WHERE user_id = p_user_id AND role = 'delivery_staff'
    ) OR public.is_admin(p_user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 23. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.branch_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customer_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.branch_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotion_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Profiles: Anyone authenticated can read own profile; Admins read all
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT TO authenticated USING (auth.uid() = id OR public.is_admin(auth.uid()));

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- User Roles: Read own role; Admins manage
CREATE POLICY "Users can read own roles" ON public.user_roles
    FOR SELECT TO authenticated USING (user_id = auth.uid() OR public.is_admin(auth.uid()));

CREATE POLICY "Admins can manage user roles" ON public.user_roles
    FOR ALL TO authenticated USING (public.is_admin(auth.uid()));

-- Branches: Publicly readable; Admins manage
CREATE POLICY "Public read active branches" ON public.branches
    FOR SELECT TO anon, authenticated USING (is_active = true OR public.is_admin(auth.uid()));

CREATE POLICY "Admins manage branches" ON public.branches
    FOR ALL TO authenticated USING (public.is_admin(auth.uid()));

-- Branch Staff: Staff read own branch assignment; Admins manage
CREATE POLICY "Staff read own assignment" ON public.branch_staff
    FOR SELECT TO authenticated USING (user_id = auth.uid() OR public.is_admin(auth.uid()));

CREATE POLICY "Admins manage branch staff" ON public.branch_staff
    FOR ALL TO authenticated USING (public.is_admin(auth.uid()));

-- Customer Addresses: Users manage own addresses
CREATE POLICY "Users manage own addresses" ON public.customer_addresses
    FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Categories: Publicly readable; Admins manage
CREATE POLICY "Public read categories" ON public.categories
    FOR SELECT TO anon, authenticated USING (is_active = true OR public.is_admin(auth.uid()));

CREATE POLICY "Admins manage categories" ON public.categories
    FOR ALL TO authenticated USING (public.is_admin(auth.uid()));

-- Products: Publicly readable; Admins manage
CREATE POLICY "Public read products" ON public.products
    FOR SELECT TO anon, authenticated USING (is_active = true OR public.is_admin(auth.uid()));

CREATE POLICY "Admins manage products" ON public.products
    FOR ALL TO authenticated USING (public.is_admin(auth.uid()));

-- Branch Inventory: Publicly viewable for available stock; Staff & Admin manage
CREATE POLICY "Public read branch inventory" ON public.branch_inventory
    FOR SELECT TO anon, authenticated USING (is_active = true OR public.is_admin(auth.uid()));

CREATE POLICY "Staff update assigned branch inventory" ON public.branch_inventory
    FOR UPDATE TO authenticated
    USING (public.is_branch_staff(auth.uid(), branch_id))
    WITH CHECK (public.is_branch_staff(auth.uid(), branch_id));

CREATE POLICY "Admins manage branch inventory" ON public.branch_inventory
    FOR ALL TO authenticated USING (public.is_admin(auth.uid()));

-- Promotions: Public read active promotions; Admins manage
CREATE POLICY "Public read active promotions" ON public.promotions
    FOR SELECT TO anon, authenticated USING (is_active = true AND end_time > now() OR public.is_admin(auth.uid()));

CREATE POLICY "Admins manage promotions" ON public.promotions
    FOR ALL TO authenticated USING (public.is_admin(auth.uid()));

CREATE POLICY "Public read promotion products" ON public.promotion_products
    FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "Admins manage promotion products" ON public.promotion_products
    FOR ALL TO authenticated USING (public.is_admin(auth.uid()));

-- Carts: Customer manages own cart
CREATE POLICY "Users manage own cart" ON public.carts
    FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users manage own cart items" ON public.cart_items
    FOR ALL TO authenticated USING (
        EXISTS (SELECT 1 FROM public.carts WHERE id = cart_items.cart_id AND user_id = auth.uid())
    ) WITH CHECK (
        EXISTS (SELECT 1 FROM public.carts WHERE id = cart_items.cart_id AND user_id = auth.uid())
    );

-- Orders: Customer reads own; Branch Staff reads branch orders; Delivery reads assigned; Admin reads all
CREATE POLICY "Order view access" ON public.orders
    FOR SELECT TO authenticated
    USING (
        customer_id = auth.uid() OR
        public.is_branch_staff(auth.uid(), branch_id) OR
        assigned_delivery_staff_id = auth.uid() OR
        public.is_admin(auth.uid())
    );

CREATE POLICY "Order items view access" ON public.order_items
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.orders o
            WHERE o.id = order_items.order_id AND (
                o.customer_id = auth.uid() OR
                public.is_branch_staff(auth.uid(), o.branch_id) OR
                o.assigned_delivery_staff_id = auth.uid() OR
                public.is_admin(auth.uid())
            )
        )
    );

-- Delivery Assignments: Delivery staff read assigned; Branch staff / admin manage
CREATE POLICY "Delivery view access" ON public.delivery_assignments
    FOR SELECT TO authenticated
    USING (
        delivery_staff_id = auth.uid() OR
        public.is_admin(auth.uid()) OR
        EXISTS (
            SELECT 1 FROM public.orders o
            WHERE o.id = delivery_assignments.order_id AND public.is_branch_staff(auth.uid(), o.branch_id)
        )
    );

CREATE POLICY "Staff manage delivery assignments" ON public.delivery_assignments
    FOR ALL TO authenticated
    USING (
        public.is_admin(auth.uid()) OR
        EXISTS (
            SELECT 1 FROM public.orders o
            WHERE o.id = delivery_assignments.order_id AND public.is_branch_staff(auth.uid(), o.branch_id)
        )
    );

-- Order Status History: Viewable by authorized actors
CREATE POLICY "History view access" ON public.order_status_history
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.orders o
            WHERE o.id = order_status_history.order_id AND (
                o.customer_id = auth.uid() OR
                public.is_branch_staff(auth.uid(), o.branch_id) OR
                o.assigned_delivery_staff_id = auth.uid() OR
                public.is_admin(auth.uid())
            )
        )
    );

-- Notifications: User manages own
CREATE POLICY "Users read own notifications" ON public.notifications
    FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Payments: Viewable by owner, staff, admin
CREATE POLICY "Payments view access" ON public.payments
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.orders o
            WHERE o.id = payments.order_id AND (
                o.customer_id = auth.uid() OR
                public.is_branch_staff(auth.uid(), o.branch_id) OR
                public.is_admin(auth.uid())
            )
        )
    );

-- ============================================================================
-- 24. TRANSACTIONAL ATOMIC RPC: CHECKOUT ORDER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.create_order_atomic(
    p_customer_id UUID,
    p_branch_id TEXT,
    p_delivery_address_id UUID,
    p_customer_name TEXT,
    p_customer_phone TEXT,
    p_delivery_address_text TEXT,
    p_payment_method TEXT,
    p_delivery_slot TEXT,
    p_delivery_instructions TEXT,
    p_items JSONB, -- Array of {product_id, quantity}
    p_idempotency_key TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_order_id UUID;
    v_order_number TEXT;
    v_subtotal_paise INT := 0;
    v_delivery_fee_paise INT := 2900;
    v_discount_paise INT := 0;
    v_total_paise INT := 0;
    v_item JSONB;
    v_prod_id TEXT;
    v_qty INT;
    v_price_paise INT;
    v_item_total INT;
    v_prod_name TEXT;
    v_prod_unit TEXT;
    v_current_stock INT;
    v_branch_min INT;
    v_free_thresh INT;
    v_std_fee INT;
    v_existing_order_id UUID;
BEGIN
    -- Idempotency check
    IF p_idempotency_key IS NOT NULL THEN
        SELECT id INTO v_existing_order_id FROM public.orders WHERE idempotency_key = p_idempotency_key;
        IF v_existing_order_id IS NOT NULL THEN
            RETURN jsonb_build_object('success', true, 'order_id', v_existing_order_id, 'is_duplicate', true);
        END IF;
    END IF;

    -- Fetch branch rules
    SELECT min_order_amount_paise, free_delivery_threshold_paise, standard_delivery_fee_paise
    INTO v_branch_min, v_free_thresh, v_std_fee
    FROM public.branches
    WHERE id = p_branch_id AND is_active = true AND is_open = true;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Selected branch is currently inactive or closed.';
    END IF;

    -- Generate unique order number (e.g. KF-BLR-2026-XXXX)
    v_order_number := 'KF-' || UPPER(SUBSTRING(p_branch_id FROM 8)) || '-' || TO_CHAR(now(), 'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');

    -- Validate inventory and calculate authoritative prices
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_prod_id := v_item->>'product_id';
        v_qty := (v_item->>'quantity')::INT;

        -- Lock inventory row FOR UPDATE
        SELECT bi.stock_quantity, COALESCE(bi.price_paise, p.base_price_paise), p.name, p.unit
        INTO v_current_stock, v_price_paise, v_prod_name, v_prod_unit
        FROM public.branch_inventory bi
        JOIN public.products p ON p.id = bi.product_id
        WHERE bi.branch_id = p_branch_id AND bi.product_id = v_prod_id AND bi.is_active = true
        FOR UPDATE OF bi;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Product % is not available at this branch.', v_prod_id;
        END IF;

        IF v_current_stock < v_qty THEN
            RAISE EXCEPTION 'Insufficient stock for % (Available: %, Requested: %)', v_prod_name, v_current_stock, v_qty;
        END IF;

        v_item_total := v_price_paise * v_qty;
        v_subtotal_paise := v_subtotal_paise + v_item_total;
    END LOOP;

    -- Calculate delivery fee & discount rules
    IF v_subtotal_paise >= v_free_thresh THEN
        v_delivery_fee_paise := 0;
    ELSE
        v_delivery_fee_paise := v_std_fee;
    END IF;

    -- 5% automatic discount for orders over ₹500 (50000 paise)
    IF v_subtotal_paise >= 50000 THEN
        v_discount_paise := FLOOR(v_subtotal_paise * 0.05);
    END IF;

    v_total_paise := v_subtotal_paise + v_delivery_fee_paise - v_discount_paise;

    -- Insert Order
    INSERT INTO public.orders (
        order_number, customer_id, branch_id, delivery_address_id, customer_name, customer_phone,
        delivery_address_text, subtotal_paise, delivery_fee_paise, discount_paise, total_paise,
        status, payment_method, payment_status, delivery_slot, delivery_instructions, idempotency_key
    ) VALUES (
        v_order_number, p_customer_id, p_branch_id, p_delivery_address_id, p_customer_name, p_customer_phone,
        p_delivery_address_text, v_subtotal_paise, v_delivery_fee_paise, v_discount_paise, v_total_paise,
        'NEW', p_payment_method, CASE WHEN p_payment_method = 'Cash on Delivery' THEN 'PENDING' ELSE 'PAID' END,
        p_delivery_slot, p_delivery_instructions, p_idempotency_key
    ) RETURNING id INTO v_order_id;

    -- Insert Order Items and Decrement Inventory
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_prod_id := v_item->>'product_id';
        v_qty := (v_item->>'quantity')::INT;

        SELECT COALESCE(bi.price_paise, p.base_price_paise), p.name, p.unit
        INTO v_price_paise, v_prod_name, v_prod_unit
        FROM public.branch_inventory bi
        JOIN public.products p ON p.id = bi.product_id
        WHERE bi.branch_id = p_branch_id AND bi.product_id = v_prod_id;

        INSERT INTO public.order_items (
            order_id, product_id, product_name, unit, price_paise, quantity, total_paise
        ) VALUES (
            v_order_id, v_prod_id, v_prod_name, v_prod_unit, v_price_paise, v_qty, (v_price_paise * v_qty)
        );

        -- Atomically decrement stock
        UPDATE public.branch_inventory
        SET stock_quantity = stock_quantity - v_qty,
            updated_at = now()
        WHERE branch_id = p_branch_id AND product_id = v_prod_id;
    END LOOP;

    -- Insert status history event
    INSERT INTO public.order_status_history (order_id, status, notes, changed_by)
    VALUES (v_order_id, 'NEW', 'Order placed by customer', p_customer_id);

    -- Clear customer cart
    DELETE FROM public.cart_items
    WHERE cart_id IN (SELECT id FROM public.carts WHERE user_id = p_customer_id);

    -- Insert Notification
    INSERT INTO public.notifications (user_id, title, message, order_id)
    VALUES (
        p_customer_id,
        'Order Received #' || v_order_number,
        'Your fresh vegetable order has been sent to ' || p_branch_id || '.',
        v_order_id
    );

    RETURN jsonb_build_object(
        'success', true,
        'order_id', v_order_id,
        'order_number', v_order_number,
        'total_paise', v_total_paise
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 25. TRANSACTIONAL ATOMIC RPC: STATUS TRANSITION & INVENTORY RESTORATION
-- ============================================================================
CREATE OR REPLACE FUNCTION public.transition_order_status(
    p_order_id UUID,
    p_new_status TEXT,
    p_notes TEXT DEFAULT NULL,
    p_actor_id UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_order public.orders%ROWTYPE;
    v_item RECORD;
BEGIN
    SELECT * INTO v_order FROM public.orders WHERE id = p_order_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Order not found';
    END IF;

    -- Validate state transitions
    IF v_order.status = 'NEW' AND p_new_status NOT IN ('ACCEPTED', 'REJECTED', 'CANCELLED') THEN
        RAISE EXCEPTION 'Invalid transition from NEW to %', p_new_status;
    ELSIF v_order.status = 'ACCEPTED' AND p_new_status NOT IN ('PREPARING', 'CANCELLED') THEN
        RAISE EXCEPTION 'Invalid transition from ACCEPTED to %', p_new_status;
    ELSIF v_order.status = 'PREPARING' AND p_new_status NOT IN ('READY_FOR_PICKUP') THEN
        RAISE EXCEPTION 'Invalid transition from PREPARING to %', p_new_status;
    ELSIF v_order.status = 'READY_FOR_PICKUP' AND p_new_status NOT IN ('OUT_FOR_DELIVERY') THEN
        RAISE EXCEPTION 'Invalid transition from READY_FOR_PICKUP to %', p_new_status;
    ELSIF v_order.status = 'OUT_FOR_DELIVERY' AND p_new_status NOT IN ('DELIVERED') THEN
        RAISE EXCEPTION 'Invalid transition from OUT_FOR_DELIVERY to %', p_new_status;
    ELSIF v_order.status IN ('DELIVERED', 'CANCELLED', 'REJECTED') THEN
        RAISE EXCEPTION 'Cannot change status of completed/terminal order (%)', v_order.status;
    END IF;

    -- If CANCELLED or REJECTED: Restore stock back to branch inventory
    IF p_new_status IN ('CANCELLED', 'REJECTED') THEN
        FOR v_item IN SELECT product_id, quantity FROM public.order_items WHERE order_id = p_order_id
        LOOP
            UPDATE public.branch_inventory
            SET stock_quantity = stock_quantity + v_item.quantity,
                updated_at = now()
            WHERE branch_id = v_order.branch_id AND product_id = v_item.product_id;
        END LOOP;
    END IF;

    -- Update order status
    UPDATE public.orders
    SET status = p_new_status,
        rejection_reason = CASE WHEN p_new_status = 'REJECTED' THEN p_notes ELSE rejection_reason END,
        updated_at = now()
    WHERE id = p_order_id;

    -- Log status history
    INSERT INTO public.order_status_history (order_id, status, notes, changed_by)
    VALUES (p_order_id, p_new_status, p_notes, p_actor_id);

    -- Notify customer
    INSERT INTO public.notifications (user_id, title, message, order_id)
    VALUES (
        v_order.customer_id,
        'Order Update: ' || p_new_status,
        COALESCE(p_notes, 'Status changed to ' || p_new_status),
        p_order_id
    );

    RETURN jsonb_build_object('success', true, 'order_id', p_order_id, 'status', p_new_status);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 26. ANALYTICS & REPORTING RPCs
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_admin_sales_report(
    p_start_date TIMESTAMPTZ DEFAULT (now() - interval '30 days'),
    p_end_date TIMESTAMPTZ DEFAULT now(),
    p_branch_id TEXT DEFAULT NULL
)
RETURNS TABLE (
    total_orders BIGINT,
    delivered_orders BIGINT,
    cancelled_orders BIGINT,
    gross_revenue_paise BIGINT,
    net_revenue_paise BIGINT,
    total_discounts_paise BIGINT,
    avg_order_value_paise BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*)::BIGINT AS total_orders,
        COUNT(*) FILTER (WHERE status = 'DELIVERED')::BIGINT AS delivered_orders,
        COUNT(*) FILTER (WHERE status IN ('CANCELLED', 'REJECTED'))::BIGINT AS cancelled_orders,
        COALESCE(SUM(subtotal_paise + delivery_fee_paise) FILTER (WHERE status = 'DELIVERED'), 0)::BIGINT AS gross_revenue_paise,
        COALESCE(SUM(total_paise) FILTER (WHERE status = 'DELIVERED'), 0)::BIGINT AS net_revenue_paise,
        COALESCE(SUM(discount_paise) FILTER (WHERE status = 'DELIVERED'), 0)::BIGINT AS total_discounts_paise,
        COALESCE(AVG(total_paise) FILTER (WHERE status = 'DELIVERED'), 0)::BIGINT AS avg_order_value_paise
    FROM public.orders
    WHERE created_at BETWEEN p_start_date AND p_end_date
      AND (p_branch_id IS NULL OR branch_id = p_branch_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.get_bestselling_products(
    p_start_date TIMESTAMPTZ DEFAULT (now() - interval '30 days'),
    p_end_date TIMESTAMPTZ DEFAULT now(),
    p_branch_id TEXT DEFAULT NULL,
    p_limit INT DEFAULT 10
)
RETURNS TABLE (
    product_id TEXT,
    product_name TEXT,
    unit TEXT,
    total_quantity_sold BIGINT,
    total_sales_paise BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        oi.product_id,
        oi.product_name,
        oi.unit,
        SUM(oi.quantity)::BIGINT AS total_quantity_sold,
        SUM(oi.total_paise)::BIGINT AS total_sales_paise
    FROM public.order_items oi
    JOIN public.orders o ON o.id = oi.order_id
    WHERE o.status = 'DELIVERED'
      AND o.created_at BETWEEN p_start_date AND p_end_date
      AND (p_branch_id IS NULL OR o.branch_id = p_branch_id)
    GROUP BY oi.product_id, oi.product_name, oi.unit
    ORDER BY total_quantity_sold DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 27. SEED DATA: 6 PHYSICAL BRANCHES
-- ============================================================================
INSERT INTO public.branches (
    id, name, area, address, phone, opening_hours, delivery_coverage,
    estimated_delivery_minutes, min_order_amount_paise, free_delivery_threshold_paise,
    standard_delivery_fee_paise, is_open, is_accepting_orders, is_active
) VALUES
('branch_blr_01', 'Indiranagar Flagship Store', 'Indiranagar', 'Shop 14, 100 Feet Road, HAL 2nd Stage, Indiranagar, Bengaluru', '+91 80 4123 9901', '6:30 AM - 10:00 PM', 'Indiranagar, Domlur, HAL, Ulsoor, Old Airport Rd', 25, 9900, 24900, 2900, true, true, true),
('branch_blr_02', 'Koramangala Market Hub', 'Koramangala', 'Plot 42, 80 Feet Road, 4th Block, Koramangala, Bengaluru', '+91 80 4123 9902', '6:00 AM - 10:30 PM', 'Koramangala (Blocks 1-8), Ejipura, SG Palya, ST Bed', 20, 9900, 24900, 2500, true, true, true),
('branch_blr_03', 'Whitefield Farm Fresh Outlet', 'Whitefield', 'No. 8, ITPL Main Road, Prestige Ozone Junction, Whitefield, Bengaluru', '+91 80 4123 9903', '7:00 AM - 10:00 PM', 'Whitefield, Kadugodi, Hope Farm, Hoodi, Brookefield', 35, 14900, 29900, 3500, true, true, true),
('branch_blr_04', 'Jayanagar Traditional Mandi', 'Jayanagar', '12th Main Road, 4th Block, Jayanagar Shopping Complex, Bengaluru', '+91 80 4123 9904', '6:00 AM - 9:30 PM', 'Jayanagar (Blocks 1-9), JP Nagar (Phases 1-3), Basavanagudi, Banashankari', 25, 9900, 24900, 2500, true, true, true),
('branch_blr_05', 'Malleshwaram Heritage Mart', 'Malleshwaram', '8th Cross, Sampige Road, Malleshwaram, Bengaluru', '+91 80 4123 9905', '6:30 AM - 9:30 PM', 'Malleshwaram, Rajajinagar, Sadashivanagar, Vyalikaval, Seshadripuram', 30, 9900, 24900, 2900, true, true, true),
('branch_blr_06', 'HSR Layout Modern Pantry', 'HSR Layout', 'Sector 1, 27th Main Road, HSR Layout, Bengaluru', '+91 80 4123 9906', '6:30 AM - 10:00 PM', 'HSR Layout (Sectors 1-7), Bellandur, Agara, Haralur Rd', 20, 9900, 24900, 2500, true, true, true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 28. SEED DATA: 6 CATEGORIES
-- ============================================================================
INSERT INTO public.categories (id, name, local_name, icon_name, slug, sort_order, is_active) VALUES
('leafy_greens', 'Leafy Greens', 'Saag & Palak', 'eco_rounded', 'leafy-greens', 1, true),
('everyday_veggies', 'Daily Essentials', 'Roz ke Sabzi', 'local_florist_rounded', 'everyday-veggies', 2, true),
('root_veggies', 'Roots & Tubers', 'Jad Wali Sabzi', 'grass_rounded', 'root-veggies', 3, true),
('onions_potatoes', 'Onions & Potatoes', 'Pyaaz Aur Aloo', 'shopping_basket_rounded', 'onions-potatoes', 4, true),
('fresh_fruits', 'Fresh Fruits', 'Taza Phal', 'apple_rounded', 'fresh-fruits', 5, true),
('seasonal_harvest', 'Seasonal Harvest', 'Mausami Subzi', 'sunny_rounded', 'seasonal-harvest', 6, true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 29. SEED DATA: 25+ PRODUCTS (AUTHENTIC INDIAN FARM PRODUCE)
-- ============================================================================
INSERT INTO public.products (
    id, name, local_name, category_id, unit, description, storage_tips, origin,
    emoji, is_organic, is_seasonal, is_bestseller, is_active, base_price_paise, original_price_paise, image_url
) VALUES
('veg_tomato_desi', 'Desi Country Tomatoes', 'Desi Tamatar', 'everyday_veggies', '1 kg', 'Tangy, juicy country-variety tomatoes picked fresh at dawn from Kolar farms.', 'Store at room temperature away from direct sunlight.', 'Kolar, Karnataka', '🍅', false, false, true, true, 3800, 4800, 'https://images.unsplash.com/photo-1546470427-0d4db154ceb7?auto=format&fit=crop&w=600&q=80'),
('veg_tomato_hybrid', 'Hybrid Round Tomatoes', 'Hybrid Tamatar', 'everyday_veggies', '1 kg', 'Firm, thick-fleshed tomatoes ideal for everyday curries, salads, and gravies.', 'Store in a cool pantry. Refrigerate once fully ripe.', 'Hosur, Tamil Nadu', '🍅', false, false, false, true, 3200, 4000, 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&w=600&q=80'),
('veg_onion_nasik', 'Nasik Red Onions', 'Nasik Pyaaz', 'onions_potatoes', '1 kg', 'Medium-to-large pungent pink onions sourced directly from Lasalgaon, Maharashtra.', 'Keep dry in a well-ventilated basket. Do not store in plastic.', 'Lasalgaon, Maharashtra', '🧅', false, false, true, true, 3400, 4200, 'https://images.unsplash.com/photo-1618512496248-a07fe83aa8cb?auto=format&fit=crop&w=600&q=80'),
('veg_potato_jyoti', 'Jyoti Table Potatoes', 'Aloo', 'onions_potatoes', '1 kg', 'Thin-skinned, smooth mountain potatoes perfect for aloo parathas, samosas, and fries.', 'Store in a cool, dark place away from onions.', 'Hassan, Karnataka', '🥔', false, false, true, true, 2800, 3500, 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?auto=format&fit=crop&w=600&q=80'),
('veg_potato_baby', 'Baby Dum Potatoes', 'Chhota Aloo', 'onions_potatoes', '500 g', 'Tender bite-sized baby potatoes hand-graded for rich Kashmiri Dum Aloo.', 'Keep in dry burlap bag in a cool pantry.', 'Hassan, Karnataka', '🥔', false, false, false, true, 2400, 3000, 'https://images.unsplash.com/photo-1508747703725-719777637510?auto=format&fit=crop&w=600&q=80'),
('veg_palak', 'Farm Spinach Leaves', 'Palak', 'leafy_greens', '1 bunch', 'Tender dark-green spinach leaves rich in iron, harvested fresh this morning.', 'Wrap in a damp cotton cloth and refrigerate crisper.', 'Chikkaballapur, Karnataka', '🥬', true, false, true, true, 2500, 3500, 'https://images.unsplash.com/photo-1576045057995-568f588f82fb?auto=format&fit=crop&w=600&q=80'),
('veg_methi', 'Organic Fenugreek Leaves', 'Kastoori Methi', 'leafy_greens', '1 bunch', 'Fragrant, mildly bitter medicinal greens ideal for methi thepla, paneer, and dal.', 'Trim roots, wrap loosely in paper towel and chill.', 'Malur, Karnataka', '🌿', true, false, true, true, 2200, 3000, 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=600&q=80'),
('veg_coriander', 'Fresh Cilantro Bunch', 'Hara Dhania', 'leafy_greens', '1 bunch', 'Intensely aromatic native coriander with delicate roots intact.', 'Place stems in a glass of water or airtight box with paper towel.', 'Devanahalli, Karnataka', '🌿', false, false, true, true, 1500, 2000, 'https://images.unsplash.com/photo-1599940824399-b87987ceb72a?auto=format&fit=crop&w=600&q=80'),
('veg_bhindi', 'Tender Green Ladies Finger', 'Bhindi / Okra', 'everyday_veggies', '500 g', 'Crisp, seed-light tender okra without woodiness. Great for crispy kurkuri bhindi.', 'Ensure completely dry before refrigerating.', 'Ramanagara, Karnataka', '🌱', false, false, true, true, 3200, 4000, 'https://images.unsplash.com/photo-1425543103986-22abb7d7e8d2?auto=format&fit=crop&w=600&q=80'),
('veg_carrot_orange', 'Ooty Orange Carrots', 'Gajar', 'root_veggies', '500 g', 'Crunchy, naturally sweet carrots cultivated in the misty hills of Ooty.', 'Remove green tops and store in vegetable crisper box.', 'Ooty, Tamil Nadu', '🥕', false, false, true, true, 3600, 4500, 'https://images.unsplash.com/photo-1582515073490-39981397c445?auto=format&fit=crop&w=600&q=80'),
('veg_capsicum_green', 'Shimla Green Bell Pepper', 'Shimla Mirch', 'everyday_veggies', '500 g', 'Glossy, thick-walled crisp bell peppers packed with Vitamin C.', 'Refrigerate whole in the produce drawer.', 'Chikkaballapur, Karnataka', '🫑', false, false, false, true, 3800, 4800, 'https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?auto=format&fit=crop&w=600&q=80'),
('veg_cauliflower', 'White Snowball Cauliflower', 'Phool Gobhi', 'everyday_veggies', '1 pc', 'Compact creamy-white curd with fresh green protective jacket leaves.', 'Store whole in a perforated paper bag in the fridge.', 'Belagavi, Karnataka', '🥦', false, false, true, true, 4200, 5500, 'https://images.unsplash.com/photo-1568584711075-3d021a7c3ca3?auto=format&fit=crop&w=600&q=80'),
('veg_cabbage', 'Green Ball Cabbage', 'Patta Gobhi', 'everyday_veggies', '1 pc', 'Crisp, dense round heads ideal for stir-fries, chowmein, and salads.', 'Keep whole unwashed head in crisper drawer.', 'Mysuru, Karnataka', '🥬', false, false, false, true, 2600, 3200, 'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?auto=format&fit=crop&w=600&q=80'),
('veg_ginger', 'Native Malabar Ginger', 'Adrak', 'root_veggies', '250 g', 'Fiery, fiber-balanced fresh ginger with thin golden skin.', 'Keep unpeeled in a cool, ventilated cabinet or chill in ziplock.', 'Wayanad, Kerala', '🫚', true, false, true, true, 3200, 4000, 'https://images.unsplash.com/photo-1599305090598-fe179d501227?auto=format&fit=crop&w=600&q=80'),
('veg_garlic', 'Mandsaur White Garlic', 'Lahsun', 'onions_potatoes', '250 g', 'Large-cloved, easy-to-peel aromatic garlic bulbs packed with allicin.', 'Store at room temperature with plenty of air circulation.', 'Mandsaur, Madhya Pradesh', '🧄', false, false, true, true, 4500, 6000, 'https://images.unsplash.com/photo-1540148426945-6cf22a6b2383?auto=format&fit=crop&w=600&q=80'),
('veg_green_chilli', 'Kolhapuri Spiced Green Chillies', 'Hari Mirch', 'everyday_veggies', '200 g', 'Medium-hot bright green chillies essential for Indian tadka and curries.', 'Remove stems and store in an airtight container lined with tissue.', 'Kolhapur, Maharashtra', '🌶️', false, false, true, true, 1800, 2500, 'https://images.unsplash.com/photo-1588252303782-cb80119abd6d?auto=format&fit=crop&w=600&q=80'),
('veg_cucumber_desi', 'Crisp Desi Cucumber', 'Desi Kheera', 'everyday_veggies', '500 g', 'Cooling, seedless crunch, perfect for raita, kachumber, and hydration.', 'Refrigerate in a paper towel to avoid excess moisture.', 'Mandya, Karnataka', '🥒', false, false, false, true, 2200, 2800, 'https://images.unsplash.com/photo-1449300079323-02e209d9d3a6?auto=format&fit=crop&w=600&q=80'),
('fruit_banana_yelakki', 'Mysore Yelakki Bananas', 'Elaichi Kela', 'fresh_fruits', '500 g', 'Naturally sweet, fragrant dwarf bananas beloved in Southern India.', 'Keep hung or on a fruit stand at room temperature.', 'Mysuru, Karnataka', '🍌', false, false, true, true, 4200, 5200, 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?auto=format&fit=crop&w=600&q=80'),
('fruit_apple_kinnaur', 'Kinnaur Crisp Red Apples', 'Seb', 'fresh_fruits', '1 kg', 'Sweet, juicy, high-altitude Himalayan apples with natural wax glow.', 'Refrigerate to preserve crunchiness and sweet aroma.', 'Kinnaur, Himachal Pradesh', '🍎', false, false, true, true, 17900, 22000, 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?auto=format&fit=crop&w=600&q=80'),
('fruit_pomegranate', 'Solapur Sindhuri Pomegranate', 'Anar', 'fresh_fruits', '1 kg', 'Ruby-red, soft-seeded arils bursting with sweet antioxidants.', 'Store at room temperature up to 10 days or refrigerate.', 'Solapur, Maharashtra', '🫐', false, false, false, true, 16500, 19900, 'https://images.unsplash.com/photo-1615485500704-8e990f9900f7?auto=format&fit=crop&w=600&q=80'),
('fruit_papaya', 'Taiwan 786 Sweet Red Papaya', 'Papita', 'fresh_fruits', '1 pc', 'Deep-orange, fragrant buttery flesh with gentle sweetness and digestive enzymes.', 'Ripen at room temperature until fragrant; chill before serving.', 'Dharmapuri, Tamil Nadu', '🍈', true, false, true, true, 5800, 7500, 'https://images.unsplash.com/photo-1517282009859-f000ec3b26fe?auto=format&fit=crop&w=600&q=80'),
('veg_drumstick', 'Tender Moringa Drumsticks', 'Moringa / Sahjan', 'seasonal_harvest', '250 g', 'Pulp-rich fresh drumstick pods for authentic South Indian Sambar.', 'Wrap in moist cloth and store in the vegetable tray.', 'Erode, Tamil Nadu', '🌿', true, true, true, true, 2800, 3800, 'https://images.unsplash.com/photo-1509358271058-acd22cc93898?auto=format&fit=crop&w=600&q=80'),
('veg_bitter_gourd', 'Small Spiny Bitter Gourd', 'Karela', 'seasonal_harvest', '500 g', 'Crisp, dark green karela prized for digestive and blood sugar wellness.', 'Keep dry in a cloth pouch in the refrigerator.', 'Tumakuru, Karnataka', '🥒', false, true, false, true, 3400, 4400, 'https://images.unsplash.com/photo-1518843875459-f738682238a6?auto=format&fit=crop&w=600&q=80'),
('veg_lemon', 'Kagzi Juicy Yellow Lemons', 'Nimbu', 'everyday_veggies', '4 pcs', 'Thin-skinned, high-yield citrus lemons loaded with tangy Vitamin C.', 'Refrigerate in a sealed glass jar with water to keep juicy for weeks.', 'Guntur, Andhra Pradesh', '🍋', false, false, true, true, 2000, 2500, 'https://images.unsplash.com/photo-1590502593747-42a996133562?auto=format&fit=crop&w=600&q=80')
ON CONFLICT (id) DO UPDATE SET image_url = EXCLUDED.image_url;

-- ============================================================================
-- 30. SEED DATA: BRANCH INVENTORY OVERRIDES FOR ALL 6 BRANCHES
-- ============================================================================
-- Populate inventory for each product in each branch
DO $$
DECLARE
    b_record RECORD;
    p_record RECORD;
    v_stock INT;
    v_price INT;
BEGIN
    FOR b_record IN SELECT id FROM public.branches LOOP
        FOR p_record IN SELECT id, base_price_paise FROM public.products LOOP
            -- Determine stock and price variations per branch
            v_stock := 15 + FLOOR(RANDOM() * 30)::INT;
            v_price := p_record.base_price_paise;

            -- Simulate Koramangala premium pricing
            IF b_record.id = 'branch_blr_02' THEN
                v_price := p_record.base_price_paise + 300;
            END IF;

            -- Simulate Out of Stock for Methi at Koramangala
            IF b_record.id = 'branch_blr_02' AND p_record.id = 'veg_methi' THEN
                v_stock := 0;
            END IF;

            -- Whitefield has bulk stock
            IF b_record.id = 'branch_blr_03' THEN
                v_stock := 40 + FLOOR(RANDOM() * 20)::INT;
            END IF;

            INSERT INTO public.branch_inventory (
                branch_id, product_id, price_paise, stock_quantity, low_stock_threshold, is_available, is_active
            ) VALUES (
                b_record.id, p_record.id, v_price, v_stock, 5, (v_stock > 0), true
            )
            ON CONFLICT (branch_id, product_id) DO NOTHING;
        END LOOP;
    END LOOP;
END $$;

-- ============================================================================
-- 31. SEED DATA: PROMOTIONS
-- ============================================================================
INSERT INTO public.promotions (
    code, title, description, discount_type, discount_value, min_order_amount_paise, max_discount_paise, end_time, is_active
) VALUES
('FRESH50', 'Flat ₹50 Off on Farm Harvest', 'Get ₹50 off on fresh vegetables and fruits for orders above ₹399', 'fixed', 5000, 39900, 5000, now() + interval '90 days', true),
('HEALTHY10', '10% Healthy Greens Discount', '10% discount on orders above ₹499', 'percentage', 10, 49900, 10000, now() + interval '90 days', true),
('CLEARANCE20', 'Urgent Harvest Clearance Sale', 'Special discount on surplus seasonal farm batches', 'percentage', 20, 29900, 15000, now() + interval '30 days', true)
ON CONFLICT (code) DO NOTHING;
