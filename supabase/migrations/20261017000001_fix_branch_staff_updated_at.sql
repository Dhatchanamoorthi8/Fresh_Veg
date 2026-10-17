-- Migration: Add updated_at to branch_staff and fix admin_create_staff_or_agent

ALTER TABLE public.branch_staff 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_branch_staff_updated_at') THEN
        CREATE TRIGGER update_branch_staff_updated_at
        BEFORE UPDATE ON public.branch_staff
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

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

    IF p_role NOT IN ('branch_staff', 'delivery_staff', 'branch_admin') THEN
        RAISE EXCEPTION 'Invalid role: %', p_role;
    END IF;

    IF p_role IN ('branch_staff', 'branch_admin') AND p_branch_id IS NULL THEN
        RAISE EXCEPTION 'Branch assignment is required for branch staff accounts.';
    END IF;

    IF EXISTS (SELECT 1 FROM auth.users WHERE lower(email) = lower(trim(p_email))) THEN
        RAISE EXCEPTION 'An account with email % already exists.', p_email;
    END IF;

    IF length(p_password) < 6 THEN
        RAISE EXCEPTION 'Password must be at least 6 characters.';
    END IF;

    v_new_user_id := gen_random_uuid();
    v_encrypted_pw := extensions.crypt(p_password, extensions.gen_salt('bf'));

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
        v_new_user_id,
        'authenticated',
        'authenticated',
        lower(trim(p_email)),
        v_encrypted_pw,
        now(),
        '{"provider":"email","providers":["email"]}',
        jsonb_build_object('full_name', trim(p_full_name)),
        now(),
        now(),
        '', '', '', '', '', '', '', ''
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
        v_new_user_id,
        v_new_user_id::text,
        jsonb_build_object(
            'sub', v_new_user_id::text,
            'email', lower(trim(p_email)),
            'full_name', trim(p_full_name),
            'email_verified', true,
            'phone_verified', false
        ),
        'email',
        now(),
        now(),
        now()
    );

    INSERT INTO public.profiles (id, full_name, email, is_active, created_at, updated_at)
    VALUES (v_new_user_id, trim(p_full_name), lower(trim(p_email)), true, now(), now())
    ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        email = EXCLUDED.email,
        is_active = true,
        updated_at = now();

    INSERT INTO public.user_roles (user_id, role)
    VALUES (v_new_user_id, p_role)
    ON CONFLICT (user_id, role) DO NOTHING;

    IF p_branch_id IS NOT NULL AND p_role IN ('branch_staff', 'branch_admin') THEN
        INSERT INTO public.branch_staff (user_id, branch_id, role, is_active, created_at, updated_at)
        VALUES (v_new_user_id, p_branch_id, p_role, true, now(), now())
        ON CONFLICT (user_id, branch_id) DO UPDATE SET
            role = EXCLUDED.role,
            is_active = true,
            updated_at = now();
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'User account successfully provisioned and verified.',
        'user_id', v_new_user_id,
        'email', lower(trim(p_email)),
        'role', p_role,
        'branch_id', p_branch_id
    );
END;
$$;
