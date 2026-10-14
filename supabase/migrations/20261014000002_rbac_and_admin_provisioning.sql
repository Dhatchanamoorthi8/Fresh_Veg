-- ============================================================================
-- KISANFRESH MULTI-BRANCH VEGETABLE SHOPPING PLATFORM
-- Migration: 002_rbac_and_admin_provisioning
-- Description: One-time admin bootstrap, secure staff/delivery provisioning RPCs,
--              user status management, and strict role-based access control.
-- ============================================================================

-- 1. ADD IS_ACTIVE STATUS TO PROFILES
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true;

-- 1.1 HELPER RPC TO SAFELY CHECK BOOTSTRAP STATUS FROM FRONTEND
CREATE OR REPLACE FUNCTION public.is_admin_bootstrap_available()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    RETURN NOT EXISTS (
        SELECT 1 FROM public.user_roles WHERE role = 'super_admin'
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.is_admin_bootstrap_available() TO anon, authenticated;

-- 2. ONE-TIME SECURE ADMINISTRATOR BOOTSTRAP FUNCTION
-- Locks permanently after the first super_admin is provisioned.
CREATE OR REPLACE FUNCTION public.bootstrap_initial_admin(
    p_admin_email TEXT,
    p_admin_password TEXT,
    p_admin_name TEXT,
    p_bootstrap_secret TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
    v_existing_admin_count INT;
    v_admin_id UUID;
    v_encrypted_pw TEXT;
    v_expected_secret TEXT := 'KisanFresh_Bootstrap_2026_SecureAdmin!';
BEGIN
    -- Check if any super_admin already exists
    SELECT count(*) INTO v_existing_admin_count
    FROM public.user_roles
    WHERE role = 'super_admin';

    IF v_existing_admin_count > 0 THEN
        RAISE EXCEPTION 'Bootstrap locked: Initial administrator already provisioned. Use standard admin management.';
    END IF;

    -- Verify bootstrap secret
    IF p_bootstrap_secret != v_expected_secret THEN
        RAISE EXCEPTION 'Invalid bootstrap secret key.';
    END IF;

    -- Password validation (minimum 8 characters)
    IF length(p_admin_password) < 8 THEN
        RAISE EXCEPTION 'Admin password must be at least 8 characters.';
    END IF;

    -- Generate password hash using pgcrypto
    v_encrypted_pw := extensions.crypt(p_admin_password, extensions.gen_salt('bf'));

    -- Check if user already exists in auth.users
    SELECT id INTO v_admin_id FROM auth.users WHERE email = p_admin_email;

    IF v_admin_id IS NULL THEN
        v_admin_id := gen_random_uuid();
        INSERT INTO auth.users (
            instance_id,
            id,
            aud,
            role,
            email,
            encrypted_password,
            email_confirmed_at,
            raw_app_meta_data,
            raw_user_meta_data,
            created_at,
            updated_at,
            confirmation_token,
            recovery_token,
            email_change_token_new,
            email_change,
            phone_change,
            phone_change_token,
            email_change_token_current,
            reauthentication_token
        ) VALUES (
            '00000000-0000-0000-0000-000000000000',
            v_admin_id,
            'authenticated',
            'authenticated',
            p_admin_email,
            v_encrypted_pw,
            now(),
            '{"provider":"email","providers":["email"]}',
            jsonb_build_object('full_name', p_admin_name),
            now(),
            now(),
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            ''
        );

        INSERT INTO auth.identities (
            id,
            user_id,
            provider_id,
            identity_data,
            provider,
            last_sign_in_at,
            created_at,
            updated_at
        ) VALUES (
            gen_random_uuid(),
            v_admin_id,
            v_admin_id::text,
            jsonb_build_object(
                'sub', v_admin_id::text,
                'email', p_admin_email,
                'full_name', p_admin_name,
                'email_verified', true,
                'phone_verified', false
            ),
            'email',
            now(),
            now(),
            now()
        ) ON CONFLICT (provider, provider_id) DO NOTHING;
    ELSE
        UPDATE auth.users
        SET encrypted_password = v_encrypted_pw,
            email_confirmed_at = COALESCE(email_confirmed_at, now()),
            updated_at = now(),
            confirmation_token = COALESCE(confirmation_token, ''),
            recovery_token = COALESCE(recovery_token, ''),
            email_change_token_new = COALESCE(email_change_token_new, ''),
            email_change = COALESCE(email_change, ''),
            phone_change = COALESCE(phone_change, ''),
            phone_change_token = COALESCE(phone_change_token, ''),
            email_change_token_current = COALESCE(email_change_token_current, ''),
            reauthentication_token = COALESCE(reauthentication_token, '')
        WHERE id = v_admin_id;

        INSERT INTO auth.identities (
            id,
            user_id,
            provider_id,
            identity_data,
            provider,
            last_sign_in_at,
            created_at,
            updated_at
        ) VALUES (
            gen_random_uuid(),
            v_admin_id,
            v_admin_id::text,
            jsonb_build_object(
                'sub', v_admin_id::text,
                'email', p_admin_email,
                'full_name', p_admin_name,
                'email_verified', true,
                'phone_verified', false
            ),
            'email',
            now(),
            now(),
            now()
        ) ON CONFLICT (provider, provider_id) DO NOTHING;
    END IF;

    -- Upsert profile
    INSERT INTO public.profiles (id, full_name, email, is_active, created_at, updated_at)
    VALUES (v_admin_id, p_admin_name, p_admin_email, true, now(), now())
    ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        email = EXCLUDED.email,
        is_active = true;

    -- Assign super_admin role
    INSERT INTO public.user_roles (user_id, role)
    VALUES (v_admin_id, 'super_admin')
    ON CONFLICT (user_id, role) DO NOTHING;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Initial administrator successfully provisioned and verified.',
        'user_id', v_admin_id,
        'email', p_admin_email,
        'role', 'super_admin'
    );
END;
$$;

-- 3. SECURE ADMIN PROVISIONING FUNCTION FOR STAFF AND DELIVERY AGENTS
-- Can only be called by an authenticated super_admin or branch_admin.
CREATE OR REPLACE FUNCTION public.admin_create_staff_or_agent(
    p_email TEXT,
    p_password TEXT,
    p_full_name TEXT,
    p_role TEXT,
    p_branch_id TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
    v_calling_user_id UUID;
    v_calling_user_role TEXT;
    v_new_user_id UUID;
    v_encrypted_pw TEXT;
BEGIN
    -- 1. Security Check: verify calling user is super_admin or branch_admin
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

    -- Validate role argument
    IF p_role NOT IN ('branch_staff', 'delivery_staff', 'branch_admin') THEN
        RAISE EXCEPTION 'Invalid role: %', p_role;
    END IF;

    -- Validate branch assignment for store staff
    IF p_role IN ('branch_staff', 'branch_admin') AND p_branch_id IS NULL THEN
        RAISE EXCEPTION 'Branch assignment is required for branch staff accounts.';
    END IF;

    -- Check if email already exists
    IF EXISTS (SELECT 1 FROM auth.users WHERE email = p_email) THEN
        RAISE EXCEPTION 'An account with email % already exists.', p_email;
    END IF;

    IF length(p_password) < 6 THEN
        RAISE EXCEPTION 'Password must be at least 6 characters.';
    END IF;

    v_new_user_id := gen_random_uuid();
    v_encrypted_pw := extensions.crypt(p_password, extensions.gen_salt('bf'));

    -- 2. Create user in auth.users with pre-confirmed email
    INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at
    ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        v_new_user_id,
        'authenticated',
        'authenticated',
        p_email,
        v_encrypted_pw,
        now(),
        '{"provider":"email","providers":["email"]}',
        jsonb_build_object('full_name', p_full_name),
        now(),
        now()
    );

    -- 3. Upsert profile
    INSERT INTO public.profiles (id, full_name, email, is_active, created_at, updated_at)
    VALUES (v_new_user_id, p_full_name, p_email, true, now(), now())
    ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name, email = EXCLUDED.email, is_active = true;

    -- 4. Upsert user_roles
    INSERT INTO public.user_roles (user_id, role)
    VALUES (v_new_user_id, p_role)
    ON CONFLICT (user_id, role) DO NOTHING;

    -- 5. If branch staff, assign to branch
    IF p_branch_id IS NOT NULL AND p_role IN ('branch_staff', 'branch_admin') THEN
        INSERT INTO public.branch_staff (user_id, branch_id, role, is_active)
        VALUES (v_new_user_id, p_branch_id, p_role, true)
        ON CONFLICT (user_id, branch_id) DO UPDATE SET is_active = true, role = EXCLUDED.role;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'user_id', v_new_user_id,
        'email', p_email,
        'role', p_role,
        'branch_id', p_branch_id
    );
END;
$$;

-- 4. ADMIN TOGGLE USER ACTIVE STATUS FUNCTION
CREATE OR REPLACE FUNCTION public.admin_toggle_user_active(
    p_target_user_id UUID,
    p_is_active BOOLEAN
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_calling_user_id UUID;
    v_calling_user_role TEXT;
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

    -- Prevent admin from deactivating themselves
    IF v_calling_user_id = p_target_user_id AND p_is_active = false THEN
        RAISE EXCEPTION 'Cannot deactivate your own administrator account.';
    END IF;

    -- Update profiles
    UPDATE public.profiles
    SET is_active = p_is_active, updated_at = now()
    WHERE id = p_target_user_id;

    -- Update branch_staff if applicable
    UPDATE public.branch_staff
    SET is_active = p_is_active
    WHERE user_id = p_target_user_id;

    RETURN jsonb_build_object('success', true, 'user_id', p_target_user_id, 'is_active', p_is_active);
END;
$$;

-- 5. ADMIN REASSIGN STAFF BRANCH FUNCTION
CREATE OR REPLACE FUNCTION public.admin_reassign_staff_branch(
    p_target_user_id UUID,
    p_new_branch_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_calling_user_id UUID;
    v_calling_user_role TEXT;
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

    -- Deactivate current branch assignments
    UPDATE public.branch_staff
    SET is_active = false
    WHERE user_id = p_target_user_id;

    -- Upsert new assignment
    INSERT INTO public.branch_staff (user_id, branch_id, role, is_active)
    VALUES (p_target_user_id, p_new_branch_id, 'branch_staff', true)
    ON CONFLICT (user_id, branch_id) DO UPDATE SET is_active = true;

    RETURN jsonb_build_object('success', true, 'user_id', p_target_user_id, 'new_branch_id', p_new_branch_id);
END;
$$;

-- 6. GRANT EXECUTE ON RPC FUNCTIONS TO AUTHENTICATED USERS
GRANT EXECUTE ON FUNCTION public.bootstrap_initial_admin(TEXT, TEXT, TEXT, TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.admin_create_staff_or_agent(TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_toggle_user_active(UUID, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_reassign_staff_branch(UUID, TEXT) TO authenticated;
