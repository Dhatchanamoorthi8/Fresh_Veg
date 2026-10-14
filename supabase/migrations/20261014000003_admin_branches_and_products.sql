-- Migration 20261014000003_admin_branches_and_products.sql
-- Multi-Branch Vegetable Shopping Platform - Admin Management Schema Enhancements

-- 1. Enhance branches table with code, manager details, and location specifics
ALTER TABLE public.branches ADD COLUMN IF NOT EXISTS code TEXT;
ALTER TABLE public.branches ADD COLUMN IF NOT EXISTS manager_name TEXT;
ALTER TABLE public.branches ADD COLUMN IF NOT EXISTS contact_email TEXT;
ALTER TABLE public.branches ADD COLUMN IF NOT EXISTS city TEXT DEFAULT 'Bengaluru';
ALTER TABLE public.branches ADD COLUMN IF NOT EXISTS state TEXT DEFAULT 'Karnataka';
ALTER TABLE public.branches ADD COLUMN IF NOT EXISTS pincode TEXT;

-- Backfill codes for existing branches
UPDATE public.branches 
SET code = UPPER(REPLACE(id, 'branch_', 'BR-')) 
WHERE code IS NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'branches_code_key'
    ) THEN
        ALTER TABLE public.branches ADD CONSTRAINT branches_code_key UNIQUE (code);
    END IF;
END $$;

-- 2. Enhance products table with SKU and featured flags
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS sku TEXT;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS is_featured BOOLEAN NOT NULL DEFAULT false;

-- Backfill SKU for existing products
UPDATE public.products 
SET sku = UPPER(REPLACE(id, 'veg_', 'SKU-')) 
WHERE sku IS NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'products_sku_key'
    ) THEN
        ALTER TABLE public.products ADD CONSTRAINT products_sku_key UNIQUE (sku);
    END IF;
END $$;

-- 3. Enhance categories table with optional image URL and ensure unique name
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS image_url TEXT;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'categories_name_key'
    ) THEN
        ALTER TABLE public.categories ADD CONSTRAINT categories_name_key UNIQUE (name);
    END IF;
END $$;

-- 4. Enhance promotions table with urgent sale and category discount support
ALTER TABLE public.promotions ADD COLUMN IF NOT EXISTS is_urgent_sale BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.promotions ADD COLUMN IF NOT EXISTS category_id TEXT REFERENCES public.categories(id) ON DELETE SET NULL;

-- 5. Storage RLS policies for Admins on product-images bucket
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Admins update product images'
    ) THEN
        CREATE POLICY "Admins update product images"
        ON storage.objects FOR UPDATE
        TO authenticated
        USING (bucket_id = 'product-images' AND is_admin(auth.uid()))
        WITH CHECK (bucket_id = 'product-images' AND is_admin(auth.uid()));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Admins delete product images'
    ) THEN
        CREATE POLICY "Admins delete product images"
        ON storage.objects FOR DELETE
        TO authenticated
        USING (bucket_id = 'product-images' AND is_admin(auth.uid()));
    END IF;
END $$;
