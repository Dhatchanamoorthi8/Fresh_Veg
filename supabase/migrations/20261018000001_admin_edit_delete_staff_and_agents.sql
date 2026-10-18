-- Migration: 20261018000001_admin_edit_delete_staff_and_agents.sql
-- Description: Adds secure RPCs for updating and safely deleting Staff and Delivery Partners.

-- 1. ADMIN UPDATE STAFF OR AGENT FUNCTION
CREATE OR REPLACE FUNCTION public.admin_update_staff_or_agent(
    p_target_user_id UUID,
    p_full_name TEXT,
    p_phone TEXT DEFAULT NULL,
    p_is_active BOOLEAN DEFAULT true,
    p_branch_id TEXT DEFAULT NULL,
    p_email TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_calling_user_id UUID;
    v_calling_user_role TEXT;
    v_clean_phone TEXT;
    v_clean_email TEXT;
BEGIN
    v_calling_user_id := auth.uid();
    IF v_calling_user_id IS NULL THEN
        RAISE EXCEPTION 'Unauthorized: Caller must be authenticated.';
    END IF;

    SELECT role INTO v_calling_user_role 
    FROM public.user_roles 
    WHERE user_id = v_calling_user_id AND role IN ('super_admin', 'branch_admin')
    LIMIT 1;

    IF v_calling_user_role IS NULL THEN
        RAISE EXCEPTION 'Access denied: Caller does not possess administrative privileges.';
    END IF;

    IF p_full_name IS NULL OR length(trim(p_full_name)) < 2 THEN
        RAISE EXCEPTION 'Full name must be at least 2 characters.';
    END IF;

    -- Clean phone number if provided
    IF p_phone IS NOT NULL AND length(trim(p_phone)) > 0 THEN
        v_clean_phone := regexp_replace(trim(p_phone), '[^0-9+]', '', 'g');
        IF length(v_clean_phone) < 10 THEN
            RAISE EXCEPTION 'Phone number must be at least 10 digits.';
        END IF;
    ELSE
        v_clean_phone := NULL;
    END IF;

    -- Clean and validate email if provided
    IF p_email IS NOT NULL AND length(trim(p_email)) > 0 THEN
        v_clean_email := lower(trim(p_email));
        IF v_clean_email !~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
            RAISE EXCEPTION 'Invalid email format: "%"', v_clean_email;
        END IF;

        IF EXISTS (SELECT 1 FROM auth.users WHERE lower(email) = v_clean_email AND id != p_target_user_id) THEN
            RAISE EXCEPTION 'A user with email "%" already exists.', v_clean_email;
        END IF;
    ELSE
        v_clean_email := NULL;
    END IF;

    -- Update profile
    UPDATE public.profiles
    SET full_name = trim(p_full_name),
        phone = v_clean_phone,
        email = COALESCE(v_clean_email, email),
        is_active = p_is_active,
        updated_at = now()
    WHERE id = p_target_user_id;

    -- Update auth.users metadata and email
    IF v_clean_email IS NOT NULL THEN
        UPDATE auth.users
        SET email = v_clean_email,
            raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb) || jsonb_build_object(
                'full_name', trim(p_full_name),
                'phone', v_clean_phone,
                'email', v_clean_email
            ),
            updated_at = now()
        WHERE id = p_target_user_id;
    ELSE
        UPDATE auth.users
        SET raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb) || jsonb_build_object(
                'full_name', trim(p_full_name),
                'phone', v_clean_phone
            ),
            updated_at = now()
        WHERE id = p_target_user_id;
    END IF;

    -- Update branch assignment if specified for staff
    IF p_branch_id IS NOT NULL AND length(trim(p_branch_id)) > 0 THEN
        -- Deactivate old branch assignments
        UPDATE public.branch_staff
        SET is_active = false, updated_at = now()
        WHERE user_id = p_target_user_id AND branch_id != p_branch_id;

        -- Upsert branch assignment
        INSERT INTO public.branch_staff (user_id, branch_id, role, is_active, created_at, updated_at)
        VALUES (p_target_user_id, p_branch_id, 'branch_staff', p_is_active, now(), now())
        ON CONFLICT (user_id, branch_id) DO UPDATE SET
            is_active = p_is_active,
            updated_at = now();
    ELSE
        -- Update is_active on existing branch_staff if branch_id was not explicitly changed
        UPDATE public.branch_staff
        SET is_active = p_is_active, updated_at = now()
        WHERE user_id = p_target_user_id;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'User successfully updated.',
        'user_id', p_target_user_id,
        'email', v_clean_email,
        'is_active', p_is_active
    );
END;
$$;

-- 2. ADMIN DELETE STAFF OR AGENT FUNCTION
CREATE OR REPLACE FUNCTION public.admin_delete_staff_or_agent(
    p_target_user_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_calling_user_id UUID;
    v_calling_user_role TEXT;
    v_active_delivery_count INT;
    v_active_order_count INT;
BEGIN
    v_calling_user_id := auth.uid();
    IF v_calling_user_id IS NULL THEN
        RAISE EXCEPTION 'Unauthorized: Caller must be authenticated.';
    END IF;

    SELECT role INTO v_calling_user_role 
    FROM public.user_roles 
    WHERE user_id = v_calling_user_id AND role IN ('super_admin', 'branch_admin')
    LIMIT 1;

    IF v_calling_user_role IS NULL THEN
        RAISE EXCEPTION 'Access denied: Caller does not possess administrative privileges.';
    END IF;

    -- Prevent self-deletion
    IF v_calling_user_id = p_target_user_id THEN
        RAISE EXCEPTION 'Cannot delete your own administrator account.';
    END IF;

    -- Prevent deleting super admin
    IF EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = p_target_user_id AND role = 'super_admin') THEN
        RAISE EXCEPTION 'Super administrator accounts cannot be deleted.';
    END IF;

    -- 1. Check for active delivery assignments
    SELECT count(*) INTO v_active_delivery_count
    FROM public.delivery_assignments
    WHERE delivery_staff_id = p_target_user_id
      AND status IN ('assigned', 'accepted', 'in_transit');

    IF v_active_delivery_count > 0 THEN
        RAISE EXCEPTION 'Cannot delete delivery partner: They currently have % active delivery assignment(s) in progress. Please reassign or complete those orders first.', v_active_delivery_count;
    END IF;

    -- 2. Check for active customer orders if any
    SELECT count(*) INTO v_active_order_count
    FROM public.orders
    WHERE customer_id = p_target_user_id
      AND status NOT IN ('delivered', 'cancelled');

    IF v_active_order_count > 0 THEN
        RAISE EXCEPTION 'Cannot delete user: Active ongoing order(s) exist for this account.';
    END IF;

    -- 3. Safely unlink/clean dependent records
    DELETE FROM public.delivery_assignments WHERE delivery_staff_id = p_target_user_id;
    UPDATE public.delivery_assignments SET assigned_by = NULL WHERE assigned_by = p_target_user_id;
    UPDATE public.order_status_history SET changed_by = NULL WHERE changed_by = p_target_user_id;
    UPDATE public.orders SET assigned_delivery_staff_id = NULL WHERE assigned_delivery_staff_id = p_target_user_id;

    DELETE FROM public.branch_staff WHERE user_id = p_target_user_id;
    DELETE FROM public.user_roles WHERE user_id = p_target_user_id;
    DELETE FROM public.customer_addresses WHERE user_id = p_target_user_id;
    DELETE FROM public.cart_items WHERE cart_id IN (SELECT id FROM public.carts WHERE user_id = p_target_user_id);
    DELETE FROM public.carts WHERE user_id = p_target_user_id;
    DELETE FROM public.notifications WHERE user_id = p_target_user_id;
    DELETE FROM public.profiles WHERE id = p_target_user_id;

    -- 4. Delete from auth.identities and auth.users
    DELETE FROM auth.identities WHERE user_id = p_target_user_id;
    DELETE FROM auth.users WHERE id = p_target_user_id;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Account successfully and safely removed.',
        'user_id', p_target_user_id
    );
END;
$$;

-- 3. PERMISSIONS
GRANT EXECUTE ON FUNCTION public.admin_update_staff_or_agent(UUID, TEXT, TEXT, BOOLEAN, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_delete_staff_or_agent(UUID) TO authenticated;
