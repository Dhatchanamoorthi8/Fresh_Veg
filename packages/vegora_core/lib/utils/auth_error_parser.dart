/// Enterprise-grade authentication and authorization error parser.
/// Maps Supabase auth exceptions, HTTP status codes, network errors,
/// and custom domain exceptions into human-friendly, localized error messages.
class AuthErrorParser {
  AuthErrorParser._();

  /// Parses any error into a clean, human-friendly message for presentation in UI.
  static String parse(dynamic error, {String? defaultMessage}) {
    if (error == null) return '';

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
        raw.contains('User already registered')) {
      return 'An account with this email address already exists. Please sign in instead.';
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
      return 'Too many sign-in attempts. For security reasons, please wait a moment before trying again.';
    }

    // Weak password
    if (raw.contains('weak_password') ||
        raw.contains('Password should be at least')) {
      return 'Password is too weak. Please choose a password with at least 6 characters.';
    }

    // Domain: Access Denied / Unauthorized Role
    if (raw.contains('Access Denied') ||
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
