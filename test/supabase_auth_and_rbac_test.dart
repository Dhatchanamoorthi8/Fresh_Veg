import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vegetable_shop/features/auth/login_screen.dart';
import 'package:vegetable_shop/features/auth/register_screen.dart';
import 'package:vegetable_shop/features/auth/forgot_password_screen.dart';
import 'package:vegetable_shop/features/auth/reset_password_screen.dart';
import 'package:vegora_admin_web/features/auth/admin_forgot_password_screen.dart';
import 'package:vegora_admin_web/features/auth/admin_reset_password_screen.dart';
import 'package:vegetable_shop/shared/models/user_role.dart';
import 'package:vegetable_shop/shared/repositories/supabase_auth_repository.dart';

void main() {
  group('1. RBAC & User Profile Model Tests', () {
    test('AppUserRole hierarchy and permissions are strictly defined', () {
      expect(AppUserRole.superAdmin.isAdmin, isTrue);
      expect(AppUserRole.branchAdmin.isAdmin, isTrue);
      expect(AppUserRole.customer.isAdmin, isFalse);
      expect(AppUserRole.branchStaff.isAdmin, isFalse);
      expect(AppUserRole.deliveryStaff.isAdmin, isFalse);

      expect(AppUserRole.branchStaff.isStaff, isTrue);
      expect(AppUserRole.customer.isStaff, isFalse);

      expect(AppUserRole.deliveryStaff.isDelivery, isTrue);
      expect(AppUserRole.customer.isDelivery, isFalse);
    });

    test('UserProfile JSON deserialization parses database roles and status correctly', () {
      final json = {
        'id': 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        'email': 'staff.indiranagar@vegora.in',
        'full_name': 'Ramesh Staff',
        'phone': '9876543210',
        'avatar_url': null,
        'role': 'branch_staff',
        'branch_id': 'branch_01',
        'is_active': true,
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.id, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890');
      expect(profile.email, 'staff.indiranagar@vegora.in');
      expect(profile.fullName, 'Ramesh Staff');
      expect(profile.phone, '9876543210');
      expect(profile.role, AppUserRole.branchStaff);
      expect(profile.branchId, 'branch_01');
      expect(profile.isActive, isTrue);
    });

    test(
      'Suspended/Deactivated user profile is parsed with isActive = false',
      () {
        final json = {
          'id': 'b2c3d4e5-f6a7-8901-bcde-f12345678901',
          'email': 'deactivated.driver@vegora.in',
          'full_name': 'Ex Driver',
          'role': 'delivery_staff',
          'is_active': false,
        };

        final profile = UserProfile.fromJson(json);
        expect(profile.role, AppUserRole.deliveryStaff);
        expect(profile.isActive, isFalse);
      },
    );

    test(
      'Customer profile defaults to customer role if role field is missing',
      () {
        final json = {
          'id': 'c3d4e5f6-a7b8-9012-cdef-123456789012',
          'email': 'customer@gmail.com',
          'full_name': 'Pooja Sharma',
        };

        final profile = UserProfile.fromJson(json);
        expect(profile.role, AppUserRole.customer);
        expect(profile.isActive, isTrue);
      },
    );
  });

  group('2. Customer Registration Screen Validation Tests', () {
    testWidgets(
      'Registration form rejects empty name, invalid email and short password',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: RegisterScreen())),
        );

        await tester.pumpAndSettle();

        // Find Create Account button, ensure visible in scroll view, and tap
        final createButton = find.text('Create Account');
        expect(createButton, findsOneWidget);
        await tester.ensureVisible(createButton);
        await tester.pumpAndSettle();
        await tester.tap(createButton);
        await tester.pumpAndSettle();

        // Validation errors should appear
        expect(find.text('Please enter your full name'), findsOneWidget);
        expect(find.text('Please enter your email address'), findsOneWidget);
        expect(find.text('Please create a password'), findsOneWidget);
      },
    );

    testWidgets('Registration form catches password confirmation mismatch', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RegisterScreen())),
      );

      await tester.pumpAndSettle();

      // Enter name, email, password, and different confirm password
      await tester.enterText(find.byType(TextFormField).at(0), 'Anand Kumar');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'anand@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'SecretPass123!',
      );
      await tester.enterText(
        find.byType(TextFormField).at(3),
        'DifferentPassword456!',
      );

      final createButton = find.text('Create Account');
      await tester.ensureVisible(createButton);
      await tester.pumpAndSettle();
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });

  group('3. Customer Login Screen Authentication UI Tests', () {
    testWidgets(
      'Login screen presents Email/Password, Google button, and ensures Staff/Admin portals are excluded for customer monorepo',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: LoginScreen())),
        );

        await tester.pumpAndSettle();

        // Form fields
        expect(find.text('Email Address'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Sign In'), findsOneWidget);
        expect(find.text('Continue with Google'), findsOneWidget);
        expect(find.text('Sign up'), findsOneWidget);
        expect(find.text('Forgot Password?'), findsOneWidget);

        // Dedicated Monorepo Separation: Staff & Admin logins MUST NOT be present
        expect(find.text('Staff Login'), findsNothing);
        expect(find.text('Delivery Partner'), findsNothing);
        expect(find.text('Admin Console'), findsNothing);
        expect(find.text('Store Operations & Staff Access'), findsNothing);

        // Verify NO phone OTP button or demo login button exists
        expect(find.text('Send OTP'), findsNothing);
        expect(find.text('Verify OTP'), findsNothing);
        expect(find.text('Demo Login'), findsNothing);
        expect(find.text('Continue as Guest'), findsNothing);
      },
    );

    testWidgets('Login form email validation rejects invalid email formats', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginScreen())),
      );
      await tester.pumpAndSettle();

      // Submit empty
      final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.ensureVisible(signInButton);
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email address'), findsOneWidget);

      // Submit invalid format
      await tester.enterText(find.byType(TextFormField).first, 'invalidemail');
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });
  });

  group('4. Password Recovery & Reset Password Flow Tests', () {
    testWidgets(
      'Customer ForgotPasswordScreen renders email input and recovery action',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: ForgotPasswordScreen())),
        );
        await tester.pumpAndSettle();

        expect(find.text('Forgot Password?'), findsOneWidget);
        expect(find.text('Email Address'), findsOneWidget);
        expect(find.text('Send Reset Link'), findsOneWidget);

        // Verify email validation
        final sendBtn = find.text('Send Reset Link');
        await tester.tap(sendBtn);
        await tester.pumpAndSettle();

        expect(find.text('Please enter your email address'), findsOneWidget);
      },
    );

    testWidgets(
      'Customer ResetPasswordScreen validates password confirmation and length',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: ResetPasswordScreen())),
        );
        await tester.pumpAndSettle();

        expect(find.text('Set New Password'), findsWidgets);
        expect(find.text('New Password'), findsOneWidget);
        expect(find.text('Confirm New Password'), findsOneWidget);

        final updateBtn = find.text('Update Password');
        await tester.tap(updateBtn);
        await tester.pumpAndSettle();

        expect(find.text('Please enter a new password'), findsOneWidget);

        // Short password
        await tester.enterText(find.byType(TextFormField).at(0), '123');
        await tester.tap(updateBtn);
        await tester.pumpAndSettle();
        expect(
          find.text('Password must be at least 6 characters'),
          findsOneWidget,
        );

        // Mismatched confirmation
        await tester.enterText(
          find.byType(TextFormField).at(0),
          'ValidPass123!',
        );
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'DifferentPass!',
        );
        await tester.tap(updateBtn);
        await tester.pumpAndSettle();
        expect(find.text('Passwords do not match'), findsOneWidget);
      },
    );

    testWidgets(
      'Admin ForgotPasswordScreen renders and validates administrator email',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: AdminForgotPasswordScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Admin Password Recovery'), findsOneWidget);
        expect(find.text('Administrator Email'), findsOneWidget);
        expect(find.text('Send Recovery Code'), findsOneWidget);

        final sendBtn = find.text('Send Recovery Code');
        await tester.tap(sendBtn);
        await tester.pumpAndSettle();

        expect(
          find.text('Please enter your administrator email'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Admin ResetPasswordScreen enforces 8 character minimum enterprise password',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: AdminResetPasswordScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Set New Admin Password'), findsOneWidget);
        expect(find.text('New Administrator Password'), findsOneWidget);
        expect(find.text('Confirm Administrator Password'), findsOneWidget);

        final updateBtn = find.text('Update Administrator Password');
        await tester.tap(updateBtn);
        await tester.pumpAndSettle();

        expect(find.text('Please enter a new password'), findsOneWidget);

        // Under 8 chars
        await tester.enterText(find.byType(TextFormField).at(0), 'Pass12');
        await tester.tap(updateBtn);
        await tester.pumpAndSettle();
        expect(
          find.text('Administrator password must be at least 8 characters'),
          findsOneWidget,
        );
      },
    );
  });
}
