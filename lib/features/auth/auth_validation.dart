import 'dart:convert';
import 'dart:math' as math;

// Pure input rules for the auth screens: which e-mail addresses and new
// passwords the app accepts before calling Supabase, and the "Did you mean
// …?" typo hint. No Flutter imports, so they are unit-tested directly.

/// Longest forward path SMTP can carry (RFC 5321); Supabase refuses longer.
const int _kMaxEmailLength = 254;
const int _kMaxLocalLength = 64;
const int _kMaxLabelLength = 63;

final RegExp _localPartRe = RegExp(r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+$");
final RegExp _domainLabelRe = RegExp(
  r'^[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?$',
);
final RegExp _tldRe = RegExp(r'^[A-Za-z]{2,}$');

/// Strict e-mail check run before any auth call. The old pattern accepted
/// things like `a@b..com` or `name@clinic` and the doctor only learnt the
/// address was wrong when no code ever arrived.
///
/// Accepts the trimmed [value] when it is at most 254 characters with
/// exactly one `@`; the local part is 1–64 ASCII letters, digits and the
/// symbols RFC 5322 allows unquoted, with no leading, trailing or doubled
/// dot; the domain has at least two dot-separated labels of 1–63 letters,
/// digits or hyphens (never at either end), and a TLD of two or more
/// letters.
bool isValidEmail(String value) {
  final email = value.trim();
  if (email.isEmpty || email.length > _kMaxEmailLength) return false;
  final at = email.indexOf('@');
  if (at < 0 || at != email.lastIndexOf('@')) return false;

  final local = email.substring(0, at);
  if (local.isEmpty ||
      local.length > _kMaxLocalLength ||
      !_localPartRe.hasMatch(local) ||
      local.startsWith('.') ||
      local.endsWith('.') ||
      local.contains('..')) {
    return false;
  }

  final labels = email.substring(at + 1).split('.');
  if (labels.length < 2) return false;
  for (final label in labels) {
    if (label.length > _kMaxLabelLength || !_domainLabelRe.hasMatch(label)) {
      return false;
    }
  }
  return _tldRe.hasMatch(labels.last);
}

/// Whether [value] could be an e-mail address at all: one `@`, something on
/// either side of it, no spaces.
///
/// This is the gate for signing in to an account that ALREADY EXISTS (log in,
/// forgot password), where the address was accepted by the server long ago.
/// [isValidEmail]'s stricter rules would be wrong there: an address they hold
/// but our rules dislike would lock them out of the form entirely, with no way
/// round it. Sign-up, which creates the address, uses [isValidEmail] instead.
bool looksLikeEmail(String value) {
  final email = value.trim();
  if (email.isEmpty || email.length > _kMaxEmailLength) return false;
  if (email.contains(RegExp(r'\s'))) return false;
  final at = email.indexOf('@');
  if (at <= 0 || at != email.lastIndexOf('@')) return false;
  return at < email.length - 1;
}

/// Consumer mail providers doctors in India most often sign up with, most
/// common first: on an equal distance [suggestEmailFix] picks the earlier.
const List<String> _kCommonDomains = [
  'gmail.com',
  'yahoo.com',
  'yahoo.co.in',
  'hotmail.com',
  'outlook.com',
  'icloud.com',
  'rediffmail.com',
  'live.com',
];

/// Real providers that sit one or two edits from a common one. Their users
/// must never be told they mistyped. Regional domains of the providers in
/// [_kRegionalBrands] are handled by [_isRegionalVariant] instead of being
/// listed: there are too many (hotmail.no, yahoo.co.th, outlook.cl …) for a
/// list to stay complete.
const Set<String> _kRealLookalikes = {'mail.com', 'email.com', 'ymail.com'};

/// Providers that run the same brand under country domains (hotmail.co.uk,
/// yahoo.co.za, outlook.cz, live.ca …). Gmail is deliberately absent: it has
/// no regional domains, so `gmail.co` is a typo worth pointing out.
const Set<String> _kRegionalBrands = {'yahoo', 'hotmail', 'outlook', 'live'};

/// A country-code suffix: `ch`, `co.za`, `com.vn`. Every country code is two
/// letters, and no generic TLD is, so `hotmail.con` or `yahoo.cm0` never
/// match and still get their suggestion.
final RegExp _countrySuffixRe = RegExp(r'^(?:(?:co|com)\.)?[a-z]{2}$');

/// Whether [domain] is a regional domain of a provider that has them: the
/// brand spelled exactly, then a country-code suffix. Telling that doctor
/// "Did you mean …@hotmail.com?" would point them at someone else's address,
/// which is worse than saying nothing, so these are left alone even when the
/// edit distance says they are close.
bool _isRegionalVariant(String domain) {
  final dot = domain.indexOf('.');
  if (dot <= 0) return false;
  return _kRegionalBrands.contains(domain.substring(0, dot)) &&
      _countrySuffixRe.hasMatch(domain.substring(dot + 1));
}

/// A corrected address when the domain of [value] looks like a typo of a
/// common provider (`gmial.com`, `gmail.con`, `yaho.com`, `outlok.com` …),
/// otherwise null. A mistyped domain is the usual reason a verification code
/// "never arrives".
///
/// Allows about one edit per five characters of the provider's domain, at
/// most two (so `gmail.com` and `live.com` take one, `hotmail.com` two);
/// swapped neighbours count as one edit. Never fires for a domain that is
/// already a known provider, a regional domain of one (`hotmail.ch`), or
/// clearly different (`clinic.in`), and keeps the local part exactly as typed.
String? suggestEmailFix(String value) {
  final email = value.trim();
  final at = email.indexOf('@');
  if (at <= 0 || at != email.lastIndexOf('@')) return null;
  final domain = email.substring(at + 1).toLowerCase();
  if (domain.isEmpty ||
      _kCommonDomains.contains(domain) ||
      _kRealLookalikes.contains(domain) ||
      _isRegionalVariant(domain)) {
    return null;
  }

  String? best;
  var bestDistance = 0;
  for (final known in _kCommonDomains) {
    final allowed = math.min(2, known.length ~/ 5);
    final distance = _editDistance(domain, known);
    if (distance <= allowed && (best == null || distance < bestDistance)) {
      best = known;
      bestDistance = distance;
    }
  }
  if (best == null) return null;
  final suggestion = '${email.substring(0, at)}@$best';
  return isValidEmail(suggestion) ? suggestion : null;
}

/// Optimal-string-alignment distance: insertions, deletions, substitutions
/// and swaps of two neighbouring characters each cost one.
int _editDistance(String a, String b) {
  final d = [
    for (var i = 0; i <= a.length; i++)
      [for (var j = 0; j <= b.length; j++) i == 0 ? j : (j == 0 ? i : 0)],
  ];
  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      var best = math.min(
        math.min(d[i - 1][j] + 1, d[i][j - 1] + 1),
        d[i - 1][j - 1] + cost,
      );
      if (i > 1 && j > 1 && a[i - 1] == b[j - 2] && a[i - 2] == b[j - 1]) {
        best = math.min(best, d[i - 2][j - 2] + 1);
      }
      d[i][j] = best;
    }
  }
  return d[a.length][b.length];
}

/// One requirement a new password must meet, in checklist order.
///
/// Mirrors the Supabase project's password policy (minimum length 8 and
/// "lower_upper_letters_digits_symbols") plus GoTrue's hard bcrypt limit,
/// so the server never rejects a password the checklist showed as fine.
/// `newPasswordFieldError` (auth_widgets.dart) turns each one into the
/// matching `authPasswordTooShort` / `authPasswordNeeds*` string.
enum PasswordRule { minLength, maxLength, lowercase, uppercase, digit, symbol }

/// Fewest characters a new password may have.
const int kPasswordMinLength = 8;

/// GoTrue refuses passwords longer than 72 bytes (bcrypt's input limit);
/// it counts UTF-8 bytes, so a non-Latin character uses up to four.
const int kPasswordMaxBytes = 72;

/// The characters GoTrue counts as symbols, verbatim from its
/// "lower_upper_letters_digits_symbols" setting. Anything else (a space,
/// `€`) does not satisfy [PasswordRule.symbol] on the server either.
const String kPasswordSymbols = r'''!@#$%^&*()_+-=[]{};'\:"|<>?,./`~''';

final RegExp _lowercaseRe = RegExp('[a-z]');
final RegExp _uppercaseRe = RegExp('[A-Z]');
final RegExp _digitRe = RegExp('[0-9]');

/// The rules [password] does not meet yet; empty when it is acceptable as
/// a new password (sign-up, reset). Sign-in never applies these: accounts
/// created before the policy may have weaker passwords.
Set<PasswordRule> passwordIssues(String password) => {
  if (password.runes.length < kPasswordMinLength) PasswordRule.minLength,
  if (utf8.encode(password).length > kPasswordMaxBytes) PasswordRule.maxLength,
  if (!_lowercaseRe.hasMatch(password)) PasswordRule.lowercase,
  if (!_uppercaseRe.hasMatch(password)) PasswordRule.uppercase,
  if (!_digitRe.hasMatch(password)) PasswordRule.digit,
  if (!password.split('').any(kPasswordSymbols.contains)) PasswordRule.symbol,
};
