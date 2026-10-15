/// Standardized RFC 5322 compliant email validator for Vegora.
/// Handles trimmed whitespace, modern TLDs (>4 characters), subdomains, and plus-addressing.
class EmailValidator {
  EmailValidator._();

  /// RFC 5322 compliant regex for modern email validation.
  /// - Supports username characters: letters, numbers, standard punctuation, and `+` alias tags.
  /// - Supports multi-level subdomains.
  /// - Enforces valid top-level domain (TLD) of at least 2 alpha characters (e.g. .in, .com, .online, .tech).
  static final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$",
    caseSensitive: false,
  );

  /// Checks if [value] is a valid email address.
  static bool isValid(String? value) {
    if (value == null) return false;
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.length > 254) return false;
    return _emailRegex.hasMatch(trimmed);
  }

  /// Form field validator for TextFormField widgets.
  /// Provides user-friendly feedback with optional customized [fieldName] and [example].
  static String? validate(
    String? value, {
    String fieldName = 'email address',
    String? example,
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your $fieldName';
    }
    final trimmed = value.trim();
    if (!isValid(trimmed)) {
      final hint = example != null ? ' (e.g. $example)' : '';
      return 'Enter a valid $fieldName$hint';
    }
    return null;
  }
}
