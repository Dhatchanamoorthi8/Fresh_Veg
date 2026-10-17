import 'package:supabase_flutter/supabase_flutter.dart';

/// Enterprise-grade authentication, authorization, and database error parser.
/// Maps Supabase auth exceptions, PostgreSQL errors, HTTP status codes,
/// network timeouts, and domain exceptions into human-friendly, localized error messages.
class AuthErrorParser {
  AuthErrorParser._();

  /// Parses any error into a clean, human-friendly message for presentation in UI.
  static String parse(dynamic error, {String? defaultMessage}) {
    if (error == null) return '';

    // Direct typed handling for PostgrestException
    if (error is PostgrestException) {
      final msg = error.message.toLowerCase();
      if (error.code == '23505' || msg.contains('already exists') || msg.contains('unique constraint')) {
        return 'An account with this email address already exists. Please choose a different email.';
      }
      if (error.code == '42501' || msg.contains('access denied') || msg.contains('unauthorized') || msg.contains('permission denied')) {
        return 'Access denied: You do not have administrative privileges to perform this action.';
      }
      if (msg.contains('password') && (msg.contains('6') || msg.contains('least'))) {
        return 'Password must be at least 6 characters long.';
      }
      if (msg.contains('branch assignment is required')) {
        return 'Please select a store branch to assign this staff member.';
      }
      if (error.message.isNotEmpty &&
          !msg.contains('column') &&
          !msg.contains('relation') &&
          !msg.contains('syntax error')) {
        return error.message;
      }
      return 'A database operation failed. System updates have been applied. Please try again.';
    }

    final raw = error.toString().trim();

    // Check for invalid credentials (code: invalid_credentials, status 400)
    if (raw.contains('invalid_credentials') ||
        raw.contains('Invalid login credentials') ||
        raw.contains('invalid_grant')) {
      return 'Invalid email address or password. Please verify your credentials and try again.';
    }

    // Email not confirmed
    if (raw.contains('email_not_confirmed') ||
        raw.contains('Email not confirmed') ||
        raw.contains('email_address_not_confirmed')) {
      return 'Your email address has not been confirmed yet. Please check your inbox for the confirmation link.';
    }

    // User already registered
    if (raw.contains('user_already_exists') ||
        raw.contains('already registered') ||
        raw.contains('already exists') ||
        raw.contains('User already registered')) {
      return 'An account with this email address already exists. Please choose a different email.';
    }

    // User not found
    if (raw.contains('user_not_found') || raw.contains('User not found')) {
      return 'No account was found with this email address. Please check for typos or register.';
    }

    // Rate limiting
    if (raw.contains('over_request_rate_limit') ||
        raw.contains('rate_limit') ||
        raw.contains('over_email_send_rate_limit') ||
        raw.contains('Too many requests')) {
      return 'Too many attempts. For security reasons, please wait a moment before trying again.';
    }

    // Weak password
    if (raw.contains('weak_password') ||
        raw.contains('Password should be at least') ||
        raw.contains('Password must be at least')) {
      return 'Password is too weak. Please choose a password with at least 6 characters.';
    }

    // Domain: Access Denied / Unauthorized Role
    if (raw.contains('Access Denied') ||
        raw.contains('Access denied') ||
        raw.contains('Unauthorized') ||
        raw.contains('administrator privileges') ||
        raw.contains('store staff') ||
        raw.contains('delivery partner')) {
      return raw.replaceAll('Exception:', '').trim();
    }

    // Domain: Account Deactivated / Disabled
    if (raw.contains('Account Deactivated') ||
        raw.contains('Account Disabled') ||
        raw.contains('disabled')) {
      return raw.replaceAll('Exception:', '').trim();
    }

    // Network / Socket / Timeout
    if (raw.contains('SocketException') ||
        raw.contains('ClientException') ||
        raw.contains('Failed host lookup') ||
        raw.contains('Network request failed') ||
        raw.contains('Connection refused')) {
      return 'Network connection error. Please check your internet connection and try again.';
    }

    if (raw.contains('TimeoutException') || raw.contains('timed out')) {
      return 'The request timed out. Please verify your connection and try again.';
    }

    // Fallback: strip technical wrappers
    var clean = raw
        .replaceAll(RegExp(r'AuthApiException\(.*?message:\s*'), '')
        .replaceAll(RegExp(r',\s*statusCode:\s*\d+.*?\)', dotAll: true), '')
        .replaceAll(RegExp(r'AuthException\(.*?message:\s*'), '')
        .replaceAll(RegExp(r'PostgrestException\(.*?message:\s*'), '')
        .replaceAll(RegExp(r',\s*code:\s*[^,]+', dotAll: true), '')
        .replaceAll(RegExp(r',\s*details:\s*[^,]*', dotAll: true), '')
        .replaceAll(RegExp(r',\s*hint:\s*[^)]*', dotAll: true), '')
        .replaceAll('Exception:', '')
        .replaceAll('ClientException:', '')
        .replaceAll('AuthApiException:', '')
        .replaceAll('AuthException:', '')
        .replaceAll('{', '')
        .replaceAll('}', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .trim();

    if (clean.isEmpty) {
      return defaultMessage ??
          'An error occurred during authentication. Please try again.';
    }

    // Capitalize first letter if needed
    if (clean.isNotEmpty) {
      clean = clean[0].toUpperCase() + clean.substring(1);
    }
    if (!clean.endsWith('.')) {
      clean = '$clean.';
    }

    return clean;
  }
}
