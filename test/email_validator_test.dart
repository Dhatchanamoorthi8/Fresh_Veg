import 'package:flutter_test/flutter_test.dart';
import 'package:vegora_core/vegora_core.dart';

void main() {
  group('EmailValidator Unit Tests', () {
    test('Accepts valid email formats across standard and modern TLDs', () {
      expect(EmailValidator.isValid('user@example.com'), isTrue);
      expect(EmailValidator.isValid('admin@vegora.in'), isTrue);
      expect(EmailValidator.isValid('customer.care@fresh.store'), isTrue);
      expect(EmailValidator.isValid('support+orders@company.online'), isTrue);
      expect(
        EmailValidator.isValid('staff@branch.north.vegora.technology'),
        isTrue,
      );
      expect(EmailValidator.isValid('first.last123@sub-domain.org'), isTrue);
      expect(EmailValidator.isValid('  trimmed.user@domain.com  '), isTrue);
    });

    test('Rejects invalid email addresses', () {
      expect(EmailValidator.isValid(null), isFalse);
      expect(EmailValidator.isValid(''), isFalse);
      expect(EmailValidator.isValid('   '), isFalse);
      expect(EmailValidator.isValid('plainaddress'), isFalse);
      expect(EmailValidator.isValid('@missingusername.com'), isFalse);
      expect(EmailValidator.isValid('missingdomain@'), isFalse);
      expect(EmailValidator.isValid('user@domain'), isFalse);
      expect(
        EmailValidator.isValid('user@domain.c'),
        isFalse,
      ); // Single letter TLD
      expect(EmailValidator.isValid('spaces in@domain.com'), isFalse);
    });

    test('validate helper returns appropriate error messages', () {
      expect(
        EmailValidator.validate(null, fieldName: 'email address'),
        'Please enter your email address',
      );
      expect(
        EmailValidator.validate('', fieldName: 'email address'),
        'Please enter your email address',
      );
      expect(
        EmailValidator.validate('   ', fieldName: 'administrator email'),
        'Please enter your administrator email',
      );
      expect(
        EmailValidator.validate('notanemail', fieldName: 'email address'),
        'Enter a valid email address',
      );
      expect(
        EmailValidator.validate(
          'invalid@c',
          fieldName: 'admin email',
          example: 'admin@vegora.in',
        ),
        'Enter a valid admin email (e.g. admin@vegora.in)',
      );
      expect(
        EmailValidator.validate('valid@vegora.in', fieldName: 'admin email'),
        isNull,
      );
    });
  });
}
