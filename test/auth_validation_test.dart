import 'package:flutter_test/flutter_test.dart';
import 'package:rxvarta/features/auth/auth_validation.dart';

void main() {
  group('isValidEmail', () {
    test('accepts ordinary addresses', () {
      expect(isValidEmail('doctor@clinic.com'), isTrue);
      expect(isValidEmail('dr.a.sharma@apollo.co.in'), isTrue);
      expect(isValidEmail("o'neil+rx@gmail.com"), isTrue);
      expect(isValidEmail('  spaced@gmail.com  '), isTrue, reason: 'trimmed');
    });

    test('rejects what the old loose pattern let through', () {
      // These are the cases the screens used to accept, leaving the doctor to
      // find out only when the verification e-mail never arrived.
      expect(isValidEmail('a@b..com'), isFalse);
      expect(isValidEmail('name@clinic'), isFalse, reason: 'no TLD');
      expect(isValidEmail('name@clinic.c'), isFalse, reason: 'one-char TLD');
      expect(isValidEmail('name@clinic.123'), isFalse, reason: 'numeric TLD');
      expect(isValidEmail('name@-clinic.com'), isFalse);
      expect(isValidEmail('name@clinic-.com'), isFalse);
      expect(isValidEmail('.name@clinic.com'), isFalse);
      expect(isValidEmail('name.@clinic.com'), isFalse);
      expect(isValidEmail('na..me@clinic.com'), isFalse);
    });

    test('rejects structurally broken input', () {
      expect(isValidEmail(''), isFalse);
      expect(isValidEmail('   '), isFalse);
      expect(isValidEmail('noatsign.com'), isFalse);
      expect(isValidEmail('two@at@clinic.com'), isFalse);
      expect(isValidEmail('@clinic.com'), isFalse);
      expect(isValidEmail('name@'), isFalse);
      expect(isValidEmail('na me@clinic.com'), isFalse);
    });

    test('enforces the SMTP length limits', () {
      final longLocal = 'a' * 65;
      expect(isValidEmail('$longLocal@clinic.com'), isFalse);
      expect(isValidEmail('${'a' * 64}@clinic.com'), isTrue);

      final longLabel = 'a' * 64;
      expect(isValidEmail('dr@$longLabel.com'), isFalse);

      // 254 is the longest forward path SMTP carries.
      final tooLong = '${'a' * 60}@${'b' * 63}.${'c' * 63}.${'d' * 63}.com';
      expect(tooLong.length, greaterThan(254));
      expect(isValidEmail(tooLong), isFalse);
    });
  });

  group('looksLikeEmail', () {
    test('accepts everything isValidEmail does', () {
      for (final email in const [
        'doctor@clinic.com',
        'dr.a.sharma@apollo.co.in',
        "o'neil+rx@gmail.com",
      ]) {
        expect(isValidEmail(email), isTrue, reason: email);
        expect(looksLikeEmail(email), isTrue, reason: email);
      }
    });

    test('lets an existing account in where the strict rules would not', () {
      // The point of the permissive gate: these are addresses the server
      // accepted at sign-up, so the login form must not be what refuses
      // them. Each is rejected by isValidEmail.
      for (final email in const [
        'name@clinic',
        'a@b..com',
        'name@clinic.c',
        'name@clinic.123',
        'name@-clinic.com',
        '.name@clinic.com',
      ]) {
        expect(isValidEmail(email), isFalse, reason: 'precondition: $email');
        expect(looksLikeEmail(email), isTrue, reason: email);
      }
    });

    test('still blocks input that cannot be an address at all', () {
      expect(looksLikeEmail(''), isFalse);
      expect(looksLikeEmail('   '), isFalse);
      expect(looksLikeEmail('noatsign.com'), isFalse);
      expect(looksLikeEmail('two@at@clinic.com'), isFalse);
      expect(looksLikeEmail('@clinic.com'), isFalse, reason: 'no local part');
      expect(looksLikeEmail('name@'), isFalse, reason: 'no domain');
      expect(looksLikeEmail('na me@clinic.com'), isFalse);
    });

    test(
      'enforces the 254-character SMTP limit on an otherwise good address',
      () {
        // '@clinic.com' is 11 characters. Without the '@' the length rule would
        // never be reached, so the address has to be well-formed apart from
        // its length for this to test anything.
        final atLimit = '${'a' * 243}@clinic.com';
        final overLimit = '${'a' * 244}@clinic.com';
        expect(atLimit.length, 254);
        expect(overLimit.length, 255);
        expect(looksLikeEmail(atLimit), isTrue);
        expect(looksLikeEmail(overLimit), isFalse);
      },
    );
  });

  group('suggestEmailFix', () {
    test('corrects the usual provider typos', () {
      expect(suggestEmailFix('dr@gmial.com'), 'dr@gmail.com');
      expect(suggestEmailFix('dr@gmail.con'), 'dr@gmail.com');
      expect(suggestEmailFix('dr@yaho.com'), 'dr@yahoo.com');
      expect(suggestEmailFix('dr@outlok.com'), 'dr@outlook.com');
      expect(suggestEmailFix('dr@hotmal.com'), 'dr@hotmail.com');
    });

    test('keeps the local part exactly as typed', () {
      expect(
        suggestEmailFix('Dr.A.Sharma+rx@gmial.com'),
        'Dr.A.Sharma+rx@gmail.com',
      );
    });

    test('stays silent for addresses that are already right', () {
      expect(suggestEmailFix('dr@gmail.com'), isNull);
      expect(suggestEmailFix('dr@yahoo.co.in'), isNull);
    });

    test('never second-guesses a real look-alike provider', () {
      // One or two edits from a common domain, but real. Telling these users
      // they mistyped would be worse than saying nothing.
      expect(suggestEmailFix('dr@ymail.com'), isNull);
      expect(suggestEmailFix('dr@mail.com'), isNull);
      expect(suggestEmailFix('dr@email.com'), isNull);
      expect(suggestEmailFix('dr@yahoo.co.uk'), isNull);
      expect(suggestEmailFix('dr@hotmail.ca'), isNull);
    });

    test('never points a regional provider domain at someone else', () {
      // Within two edits of hotmail.com / outlook.com / yahoo.co.in, and all
      // real. "Did you mean dr@hotmail.com?" would send the doctor to a
      // stranger's inbox.
      for (final domain in const [
        'hotmail.ch',
        'hotmail.cz',
        'hotmail.no',
        'hotmail.co.uk',
        'outlook.cl',
        'outlook.cz',
        'yahoo.co.il',
        'yahoo.co.za',
        'yahoo.co.nz',
        'yahoo.co.th',
        'yahoo.com.vn',
        'live.co.uk',
      ]) {
        expect(suggestEmailFix('dr@$domain'), isNull, reason: domain);
      }
    });

    test('still catches typos of those same providers', () {
      // The regional rule needs the brand spelled exactly AND a two-letter
      // country code; a mistyped brand or a non-country suffix still counts
      // as a typo.
      expect(suggestEmailFix('dr@hotmail.con'), 'dr@hotmail.com');
      expect(suggestEmailFix('dr@hotmial.com'), 'dr@hotmail.com');
      expect(suggestEmailFix('dr@outlok.com'), 'dr@outlook.com');
      expect(suggestEmailFix('dr@yahooo.com'), 'dr@yahoo.com');
      // Gmail has no regional domains, so gmail.co is a typo, not a country.
      expect(suggestEmailFix('dr@gmail.co'), 'dr@gmail.com');
    });

    test('stays silent for a clearly different domain', () {
      expect(suggestEmailFix('dr@apollo.co.in'), isNull);
      expect(suggestEmailFix('dr@clinic.in'), isNull);
      expect(suggestEmailFix('dr@aiims.edu'), isNull);
    });

    test('stays silent when there is no domain to judge', () {
      expect(suggestEmailFix(''), isNull);
      expect(suggestEmailFix('noatsign'), isNull);
      expect(suggestEmailFix('@gmial.com'), isNull);
      expect(suggestEmailFix('dr@'), isNull);
    });
  });

  group('passwordIssues', () {
    test('accepts a password meeting every rule', () {
      expect(passwordIssues('Clinic@2026'), isEmpty);
      expect(passwordIssues('Aa1!aaaa'), isEmpty, reason: 'exactly 8');
    });

    test('names each missing rule', () {
      expect(passwordIssues('Aa1!aaa'), contains(PasswordRule.minLength));
      expect(passwordIssues('CLINIC@2026'), contains(PasswordRule.lowercase));
      expect(passwordIssues('clinic@2026'), contains(PasswordRule.uppercase));
      expect(passwordIssues('Clinic@abc'), contains(PasswordRule.digit));
      expect(passwordIssues('Clinic2026'), contains(PasswordRule.symbol));
    });

    test('reports every unmet rule at once', () {
      expect(passwordIssues('abc'), {
        PasswordRule.minLength,
        PasswordRule.uppercase,
        PasswordRule.digit,
        PasswordRule.symbol,
      });
      expect(passwordIssues(''), contains(PasswordRule.minLength));
    });

    test('counts UTF-8 bytes against the bcrypt limit, not characters', () {
      // GoTrue refuses more than 72 BYTES. A Devanagari character is three,
      // so 25 of them are already over the limit while being 25 characters.
      final devanagari = 'क' * 25;
      expect(devanagari.runes.length, 25);
      expect(
        passwordIssues('Aa1!$devanagari'),
        contains(PasswordRule.maxLength),
      );

      // 72 ASCII characters is exactly at the limit, so not flagged.
      final atLimit = 'Aa1!${'a' * 68}';
      expect(atLimit.length, 72);
      expect(passwordIssues(atLimit), isEmpty);
    });

    test('accepts every symbol GoTrue counts as one', () {
      for (final symbol in kPasswordSymbols.split('')) {
        expect(
          passwordIssues('Aa1aaaa$symbol'),
          isEmpty,
          reason: 'symbol $symbol should satisfy the rule',
        );
      }
    });

    test('does not count a space or a non-ASCII mark as a symbol', () {
      expect(passwordIssues('Aa1aaaa '), contains(PasswordRule.symbol));
      expect(passwordIssues('Aa1aaaa€'), contains(PasswordRule.symbol));
    });
  });
}
