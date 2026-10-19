-- ============================================================================
-- VEGORA SUPABASE MIGRATION: 20261019000001
-- Description: Complete Tamil Language Support & Flexible Gram/Kilogram Quantities
-- ============================================================================

-- 1. EXTEND CATEGORIES TABLE WITH TAMIL SUPPORT
ALTER TABLE public.categories
ADD COLUMN IF NOT EXISTS name_ta TEXT;

-- 2. EXTEND PRODUCTS TABLE WITH TAMIL SUPPORT & UNIT CONFIGURATION
ALTER TABLE public.products
ADD COLUMN IF NOT EXISTS name_ta TEXT,
ADD COLUMN IF NOT EXISTS description_ta TEXT,
ADD COLUMN IF NOT EXISTS unit_type TEXT NOT NULL DEFAULT 'WEIGHT' CHECK (unit_type IN ('WEIGHT', 'COUNT', 'BUNCH')),
ADD COLUMN IF NOT EXISTS base_unit TEXT NOT NULL DEFAULT 'g',
ADD COLUMN IF NOT EXISTS min_order_quantity INT NOT NULL DEFAULT 100,
ADD COLUMN IF NOT EXISTS quantity_step INT NOT NULL DEFAULT 50,
ADD COLUMN IF NOT EXISTS allow_custom_quantity BOOLEAN NOT NULL DEFAULT true;

-- 3. EXTEND ORDER ITEMS TABLE FOR CANONICAL GRAMS
ALTER TABLE public.order_items
ADD COLUMN IF NOT EXISTS quantity_grams INT;

-- 4. UPDATE EXISTING CATEGORIES WITH TAMIL TRANSLATIONS
UPDATE public.categories SET name_ta = 'கீரை வகைகள்' WHERE id = 'leafy_greens';
UPDATE public.categories SET name_ta = 'அன்றாட காய்கறிகள்' WHERE id = 'everyday_veggies';
UPDATE public.categories SET name_ta = 'கிழங்கு வகைகள்' WHERE id = 'root_veggies';
UPDATE public.categories SET name_ta = 'வெங்காயம் & உருளைக்கிழங்கு' WHERE id = 'onions_potatoes';
UPDATE public.categories SET name_ta = 'புதிய பழங்கள்' WHERE id = 'fresh_fruits';
UPDATE public.categories SET name_ta = 'பருவகால விளைச்சல்' WHERE id = 'seasonal_harvest';

-- 5. UPDATE EXISTING PRODUCTS WITH TAMIL NAMES, DESCRIPTIONS & UNIT CONFIG
-- Weight-based vegetables (Prices normalized to Per Kilogram)
UPDATE public.products SET
    name_ta = 'நாட்டுத் தக்காளி',
    description_ta = 'கோலார் பண்ணைகளில் இருந்து தினமும் விடியற்காலையில் பறிக்கப்படும் புத்துணர்ச்சியான நாட்டு தக்காளி.',
    unit_type = 'WEIGHT',
    base_unit = 'g',
    unit = '1 kg',
    min_order_quantity = 100,
    quantity_step = 50,
    base_price_paise = 3800
WHERE id = 'veg_tomato_desi';

UPDATE public.products SET
    name_ta = 'ஹைப்ரிட் தக்காளி',
    description_ta = 'தினசரி சமையல், சாம்பார் மற்றும் சாலட்களுக்கு உகந்த கெட்டியான தக்காளி.',
    unit_type = 'WEIGHT',
    base_unit = 'g',
    unit = '1 kg',
    min_order_quantity = 100,
    quantity_step = 50,
    base_price_paise = 3200
WHERE id = 'veg_tomato_hybrid';

UPDATE public.products SET
    name_ta = 'நாசிக் வெங்காயம்',
    description_ta = 'மகாராஷ்டிராவின் லசல்கானில் இருந்து நேரடியாக வரவழைக்கப்படும் தரமான பெரிய வெங்காயம்.',
    unit_type = 'WEIGHT',
    base_unit = 'g',
    unit = '1 kg',
    min_order_quantity = 100,
    quantity_step = 50,
    base_price_paise = 3400
WHERE id = 'veg_onion_nasik';

UPDATE public.products SET
    name_ta = 'உருளைக்கிழங்கு',
    description_ta = 'மெல்லிய தோல் கொண்ட, வறுவலுக்கும் பரோட்டாவிற்கும் உகந்த மலை உருளைக்கிழங்கு.',
    unit_type = 'WEIGHT',
    base_unit = 'g',
    unit = '1 kg',
    min_order_quantity = 100,
    quantity_step = 50,
    base_price_paise = 2800
WHERE id = 'veg_potato_jyoti';

UPDATE public.products SET
    name_ta = 'சின்ன உருளைக்கிழங்கு',
    description_ta = 'தம் ஆலு மற்றும் உருளை வறுவலுக்கு ஏற்ற சுவையான உருளைக்கிழங்கு.',
    unit_type = 'WEIGHT',
    base_unit = 'g',
    unit = '1 kg',
    min_order_quantity = 100,
    quantity_step = 50,
    base_price_paise = 4800 -- Normalized from 2400 per 500g
WHERE id = 'veg_potato_baby';

UPDATE public.products SET
    name_ta = 'வெண்டைக்காய்',
    description_ta = 'விதைகள் குறைவான, பிஞ்சு வெண்டைக்காய். மொறுமொறு வெண்டைக்காய் வறுவலுக்கு சிறந்தது.',
    unit_type = 'WEIGHT',
    base_unit = 'g',
    unit = '1 kg',
    min_order_quantity = 100,
    quantity_step = 50,
    base_price_paise = 6400 -- Normalized from 3200 per 500g
WHERE id = 'veg_bhindi';

UPDATE public.products SET
    name_ta = 'ஊட்டி கேரட்',
    description_ta = 'ஊட்டி மலைகளில் இயற்கை முறையில் விளைவிக்கப்பட்ட இனிப்பான, மொறுமொறு கேரட்.',
    unit_type = 'WEIGHT',
    base_unit = 'g',
    unit = '1 kg',
    min_order_quantity = 100,
    quantity_step = 50,
    base_price_paise = 7200 -- Normalized from 3600 per 500g
WHERE id = 'veg_carrot_orange';

UPDATE public.products SET
    name_ta = 'பச்சை குடைமிளகாய்',
    description_ta = 'வைட்டமின் சி நிறைந்த, பளபளப்பான கெட்டியான குடைமிளகாய்.',
    unit_type = 'WEIGHT',
    base_unit = 'g',
    unit = '1 kg',
    min_order_quantity = 100,
    quantity_step = 50,
    base_price_paise = 7600 -- Normalized from 3800 per 500g
WHERE id = 'veg_capsicum_green';

UPDATE public.products SET
    name_ta = 'இஞ்சி',
    description_ta = 'காரமும் மணமும் நிறைந்த இயற்கை நாட்டு இஞ்சி.',
    unit_type = 'WEIGHT',
    base_unit = 'g',
    unit = '1 kg',
    min_order_quantity = 50,
    quantity_step = 50,
    base_price_paise = 12800 -- Normalized from 3200 per 250g
WHERE id = 'veg_ginger';

UPDATE public.products SET
    name_ta = 'பூண்டு',
    description_ta = 'பெரிய பற்கள் கொண்ட, எளிதில் உரிக்கக்கூடிய நறுமண வெள்ளை பூண்டு.',
    unit_type = 'WEIGHT',
    base_unit = 'g',
    unit = '1 kg',
    min_order_quantity = 50,
    quantity_step = 50,
    base_price_paise = 18000 -- Normalized from 4500 per 250g
WHERE id = 'veg_garlic';

UPDATE public.products SET
    name_ta = 'பச்சை மிளகாய்',
    description_ta = 'சமையலுக்கு அவசியமான காரசாரமான ஃபிரெஷ் பச்சை மிளகாய்.',
    unit_type = 'WEIGHT',
    base_unit = 'g',
    unit = '1 kg',
    min_order_quantity = 50,
    quantity_step = 50,
    base_price_paise = 9000 -- Normalized from 1800 per 200g
WHERE id = 'veg_green_chilli';

UPDATE public.products SET
    name_ta = 'நாட்டு வெள்ளரிக்காய்',
    description_ta = 'உடலுக்கு குளிர்ச்சியூட்டும் சுவையான நீர்ச்சத்து நிறைந்த வெள்ளரி.',
    unit_type = 'WEIGHT',
    base_unit = 'g',
    unit = '1 kg',
    min_order_quantity = 100,
    quantity_step = 50,
    base_price_paise = 4400 -- Normalized from 2200 per 500g
WHERE id = 'veg_cucumber_desi';

UPDATE public.products SET
    name_ta = 'முருங்கைக்காய்',
    description_ta = 'சுவையான சாம்பாருக்கு ஏற்ற சதைப்பற்றுள்ள நாட்டு முருங்கைக்காய்.',
    unit_type = 'WEIGHT',
    base_unit = 'g',
    unit = '1 kg',
    min_order_quantity = 100,
    quantity_step = 50,
    base_price_paise = 11200 -- Normalized from 2800 per 250g
WHERE id = 'veg_drumstick';

UPDATE public.products SET
    name_ta = 'பாகற்காய்',
    description_ta = 'மருத்துவ குணம் கொண்ட, ஆரோக்கியமான இயற்கை பாகற்காய்.',
    unit_type = 'WEIGHT',
    base_unit = 'g',
    unit = '1 kg',
    min_order_quantity = 100,
    quantity_step = 50,
    base_price_paise = 6800 -- Normalized from 3400 per 500g
WHERE id = 'veg_bitter_gourd';

UPDATE public.products SET
    name_ta = 'ஏலக்கி வாழைப்பழம்',
    description_ta = 'இயற்கையான நறுமணமும் அதிக இனிப்பும் கொண்ட நாட்டு ஏலக்கி வாழைப்பழம்.',
    unit_type = 'WEIGHT',
    base_unit = 'g',
    unit = '1 kg',
    min_order_quantity = 250,
    quantity_step = 50,
    base_price_paise = 8400 -- Normalized from 4200 per 500g
WHERE id = 'fruit_banana_yelakki';

UPDATE public.products SET
    name_ta = 'ஆப்பிள்',
    description_ta = 'இமயமலை சாரலில் விளைந்த மொறுமொறுப்பான, சுவையான சிகப்பு ஆப்பிள்.',
    unit_type = 'WEIGHT',
    base_unit = 'g',
    unit = '1 kg',
    min_order_quantity = 250,
    quantity_step = 100,
    base_price_paise = 17900
WHERE id = 'fruit_apple_kinnaur';

UPDATE public.products SET
    name_ta = 'மாதுளம்பழம்',
    description_ta = 'ஆன்டிஆக்ஸிடன்ட்கள் நிறைந்த, முத்து போன்ற மென்மையான மாதுளை விதைகள்.',
    unit_type = 'WEIGHT',
    base_unit = 'g',
    unit = '1 kg',
    min_order_quantity = 250,
    quantity_step = 100,
    base_price_paise = 16500
WHERE id = 'fruit_pomegranate';

-- Bunch-based products (Greens)
UPDATE public.products SET
    name_ta = 'பசலைக் கீரை',
    description_ta = 'இரும்புச்சத்து நிறைந்த, அன்றாடம் பறிக்கப்பட்ட பசுமையான கீரை கட்டு.',
    unit_type = 'BUNCH',
    base_unit = 'bunch',
    min_order_quantity = 1,
    quantity_step = 1
WHERE id = 'veg_palak';

UPDATE public.products SET
    name_ta = 'வெந்தயக் கீரை',
    description_ta = 'மருத்துவ குணமும் நறுமணமும் கொண்ட பசுமையான வெந்தயக் கீரை.',
    unit_type = 'BUNCH',
    base_unit = 'bunch',
    min_order_quantity = 1,
    quantity_step = 1
WHERE id = 'veg_methi';

UPDATE public.products SET
    name_ta = 'கொத்தமல்லித் தழை',
    description_ta = 'தீவிர நறுமணம் கொண்ட புதிய நாட்டு கொத்தமல்லி கட்டு.',
    unit_type = 'BUNCH',
    base_unit = 'bunch',
    min_order_quantity = 1,
    quantity_step = 1
WHERE id = 'veg_coriander';

-- Count-based products (Pieces)
UPDATE public.products SET
    name_ta = 'காலிஃபிளவர்',
    description_ta = 'கிரீமி-வெள்ளை நிறமுடைய அடர்த்தியான புதிய காலிஃபிளவர்.',
    unit_type = 'COUNT',
    base_unit = 'pc',
    min_order_quantity = 1,
    quantity_step = 1
WHERE id = 'veg_cauliflower';

UPDATE public.products SET
    name_ta = 'முட்டைக்கோஸ்',
    description_ta = 'பொரியல் மற்றும் சாலட்டுகளுக்கு உகந்த புதிய பச்சை முட்டைக்கோஸ்.',
    unit_type = 'COUNT',
    base_unit = 'pc',
    min_order_quantity = 1,
    quantity_step = 1
WHERE id = 'veg_cabbage';

UPDATE public.products SET
    name_ta = 'பப்பாளி',
    description_ta = 'செரிமானத்திற்கு உதவும் சுவையான செழுமையான பப்பாளி பழம்.',
    unit_type = 'COUNT',
    base_unit = 'pc',
    min_order_quantity = 1,
    quantity_step = 1
WHERE id = 'fruit_papaya';

UPDATE public.products SET
    name_ta = 'எலுமிச்சம்பழம்',
    description_ta = 'சாறு நிறைந்த புதிய மஞ்சள் எலுமிச்சை பழங்கள்.',
    unit_type = 'COUNT',
    base_unit = 'pcs',
    min_order_quantity = 1,
    quantity_step = 1
WHERE id = 'veg_lemon';

-- 6. NORMALIZE EXISTING INVENTORY STOCK TO GRAMS (WEIGHT-BASED PRODUCTS)
-- Existing stock values (< 500) were entered as kilograms; scale them to canonical integer grams (e.g. 25 kg -> 25,000 g).
UPDATE public.branch_inventory bi
SET stock_quantity = bi.stock_quantity * 1000
FROM public.products p
WHERE bi.product_id = p.id
  AND p.unit_type = 'WEIGHT'
  AND bi.stock_quantity < 500;

-- Normalize branch-specific price overrides to per-kg if previously per-portion
UPDATE public.branch_inventory bi
SET price_paise = CASE
    WHEN p.id IN ('veg_bhindi', 'veg_carrot_orange', 'veg_capsicum_green', 'veg_cucumber_desi', 'fruit_banana_yelakki', 'veg_bitter_gourd') AND bi.price_paise < 5000 THEN bi.price_paise * 2
    WHEN p.id IN ('veg_ginger', 'veg_garlic', 'veg_drumstick') AND bi.price_paise < 6000 THEN bi.price_paise * 4
    WHEN p.id = 'veg_green_chilli' AND bi.price_paise < 4000 THEN bi.price_paise * 5
    ELSE bi.price_paise
END
FROM public.products p
WHERE bi.product_id = p.id
  AND p.unit_type = 'WEIGHT'
  AND bi.price_paise IS NOT NULL;

-- 7. UPDATE TRANSACTIONAL ATOMIC RPC: CHECKOUT WITH GRAM-LEVEL NORMALIZATION
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
    p_items JSONB, -- Array of {product_id, quantity (in grams or count)}
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
    v_unit_type TEXT;
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

        IF v_qty <= 0 THEN
            RAISE EXCEPTION 'Invalid quantity % for product %', v_qty, v_prod_id;
        END IF;

        -- Lock inventory row FOR UPDATE
        SELECT bi.stock_quantity, COALESCE(bi.price_paise, p.base_price_paise), p.name, p.unit, p.unit_type
        INTO v_current_stock, v_price_paise, v_prod_name, v_prod_unit, v_unit_type
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

        -- Price formula:
        -- For weight-based: line_total = (price_per_kg * quantity_grams) / 1000
        -- For count-based:  line_total = price_per_piece * quantity
        IF v_unit_type = 'WEIGHT' THEN
            v_item_total := ROUND((v_price_paise::NUMERIC * v_qty::NUMERIC) / 1000.0)::INT;
        ELSE
            v_item_total := v_price_paise * v_qty;
        END IF;

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

        SELECT COALESCE(bi.price_paise, p.base_price_paise), p.name, p.unit, p.unit_type
        INTO v_price_paise, v_prod_name, v_prod_unit, v_unit_type
        FROM public.branch_inventory bi
        JOIN public.products p ON p.id = bi.product_id
        WHERE bi.branch_id = p_branch_id AND bi.product_id = v_prod_id;

        IF v_unit_type = 'WEIGHT' THEN
            v_item_total := ROUND((v_price_paise::NUMERIC * v_qty::NUMERIC) / 1000.0)::INT;
        ELSE
            v_item_total := v_price_paise * v_qty;
        END IF;

        INSERT INTO public.order_items (
            order_id, product_id, product_name, unit, price_paise, quantity, quantity_grams, total_paise
        ) VALUES (
            v_order_id,
            v_prod_id,
            v_prod_name,
            CASE WHEN v_unit_type = 'WEIGHT' THEN 'g' ELSE v_prod_unit END,
            v_price_paise,
            v_qty,
            CASE WHEN v_unit_type = 'WEIGHT' THEN v_qty ELSE NULL END,
            v_item_total
        );

        -- Atomically decrement stock in canonical grams or piece count
        UPDATE public.branch_inventory
        SET stock_quantity = stock_quantity - v_qty,
            updated_at = now()
        WHERE branch_id = p_branch_id AND product_id = v_prod_id;
    END LOOP;

    -- Insert initial status history
    INSERT INTO public.order_status_history (order_id, status, notes)
    VALUES (v_order_id, 'NEW', 'Customer placed order with atomic inventory verification');

    RETURN jsonb_build_object(
        'success', true,
        'order_id', v_order_id,
        'order_number', v_order_number,
        'total_paise', v_total_paise
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
