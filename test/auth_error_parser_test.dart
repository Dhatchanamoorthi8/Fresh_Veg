import 'package:flutter_test/flutter_test.dart';
import 'package:vegetable_shop/core/utils/auth_error_parser.dart';

void main() {
  group('AuthErrorParser Unit Tests', () {
    test('Correctly maps Supabase AuthApiException for invalid credentials', () {
      const rawError =
          'AuthApiException(message: Invalid login credentials, statusCode: 400, code: invalid_credentials)';
      final result = AuthErrorParser.parse(rawError);

      expect(
        result,
        'Invalid email address or password. Please verify your credentials and try again.',
      );
    });

    test('Correctly maps invalid_grant exception', () {
      const rawError =
          'AuthApiException(message: invalid_grant, statusCode: 400)';
      final result = AuthErrorParser.parse(rawError);

      expect(
        result,
        'Invalid email address or password. Please verify your credentials and try again.',
      );
    });

    test('Correctly maps unconfirmed email', () {
      const rawError =
          'AuthApiException(message: Email not confirmed, statusCode: 400, code: email_not_confirmed)';
      final result = AuthErrorParser.parse(rawError);

      expect(
        result,
        'Your email address has not been confirmed yet. Please check your inbox for the confirmation link.',
      );
    });

    test('Correctly maps user already exists / registered', () {
      const rawError =
          'AuthApiException(message: User already registered, statusCode: 422, code: user_already_exists)';
      final result = AuthErrorParser.parse(rawError);

      expect(
        result,
        'An account with this email address already exists. Please sign in instead.',
      );
    });

    test('Correctly maps rate limit errors', () {
      const rawError =
          'AuthApiException(message: over_request_rate_limit, statusCode: 429)';
      final result = AuthErrorParser.parse(rawError);

      expect(
        result,
        'Too many sign-in attempts. For security reasons, please wait a moment before trying again.',
      );
    });

    test('Correctly maps weak password error', () {
      const rawError =
          'AuthApiException(message: Password should be at least 6 characters, code: weak_password)';
      final result = AuthErrorParser.parse(rawError);

      expect(
        result,
        'Password is too weak. Please choose a password with at least 6 characters.',
      );
    });

    test('Preserves domain Access Denied and Account Deactivated exceptions cleanly', () {
      const rawAccessDenied =
          'Exception: Access Denied: Your account does not have administrator privileges.';
      expect(
        AuthErrorParser.parse(rawAccessDenied),
        'Access Denied: Your account does not have administrator privileges.',
      );

      const rawDeactivated =
          'Exception: Account Deactivated: This administrator account has been disabled.';
      expect(
        AuthErrorParser.parse(rawDeactivated),
        'Account Deactivated: This administrator account has been disabled.',
      );
    });

    test('Correctly maps socket and network exceptions', () {
      const rawNetwork =
          'ClientException: SocketException: Failed host lookup: xyz.supabase.co';
      final result = AuthErrorParser.parse(rawNetwork);

      expect(
        result,
        'Network connection error. Please check your internet connection and try again.',
      );
    });

    test('Cleans generic technical wrappers into clean sentences', () {
      const rawGeneric =
          'Exception: Unexpected database query failure occurred';
      final result = AuthErrorParser.parse(rawGeneric);

      expect(result, 'Unexpected database query failure occurred.');
    });

    test('Gracefully handles null or empty input', () {
      expect(AuthErrorParser.parse(null), '');
      expect(
        AuthErrorParser.parse(''),
        'An error occurred during authentication. Please try again.',
      );
    });
  });
}
