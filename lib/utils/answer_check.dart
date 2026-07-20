/// Forgiving answer checking tuned for young children.
///
/// Kids type on unfamiliar keyboards and can't easily produce French accents
/// (é, è, ç, …) or Kabyle special letters (ɣ, ḥ, ḍ, ṭ, ẓ, ɛ, č). So we:
///   1. Normalize case/whitespace/punctuation.
///   2. Fold French accents to base letters AND map Kabyle special letters to
///      their closest ASCII base, so an un-accented spelling still counts.
///   3. Allow a small Levenshtein edit distance for genuine typos.
class AnswerCheck {
  /// Characters that should be folded to a base ASCII letter before compare.
  static const Map<String, String> _fold = {
    // French accents
    'à': 'a', 'â': 'a', 'ä': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'î': 'i', 'ï': 'i',
    'ô': 'o', 'ö': 'o',
    'ù': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c',
    'œ': 'oe', 'æ': 'ae',
    // Kabyle (Latin Berber) special letters -> nearest base
    'ɣ': 'g', 'ḥ': 'h', 'ḍ': 'd', 'ṭ': 't',
    'ẓ': 'z', 'ṛ': 'r', 'ṣ': 's', 'ɛ': 'a',
    'č': 'c', 'ǧ': 'j', 'ɛ̃': 'a',
  };

  static String normalize(String input) {
    var s = input.toLowerCase().trim();
    // Unify apostrophes/quotes and hyphens, drop terminal punctuation.
    s = s.replaceAll(RegExp("[’'`´]"), '');
    s = s.replaceAll(RegExp(r'[-–—]'), ' ');
    s = s.replaceAll(RegExp(r'[.!?,;:]'), '');
    // Fold special characters.
    final buffer = StringBuffer();
    for (final ch in s.split('')) {
      buffer.write(_fold[ch] ?? ch);
    }
    // Collapse internal whitespace.
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// True when [actual] is close enough to [expected] to count as correct.
  static bool isAcceptable(String expected, String actual) {
    final e = normalize(expected);
    final a = normalize(actual);
    if (e.isEmpty) return a.isEmpty;
    if (e == a) return true;

    // Tolerance scales with word length: short words must be near-exact.
    final tolerance = e.length <= 4
        ? 1
        : e.length <= 8
            ? 2
            : 3;
    return _levenshtein(e, a) <= tolerance;
  }

  static int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final prev = List<int>.generate(b.length + 1, (i) => i);
    final curr = List<int>.filled(b.length + 1, 0);

    for (var i = 0; i < a.length; i++) {
      curr[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final cost = a.codeUnitAt(i) == b.codeUnitAt(j) ? 0 : 1;
        curr[j + 1] = [
          curr[j] + 1, // insertion
          prev[j + 1] + 1, // deletion
          prev[j] + cost, // substitution
        ].reduce((x, y) => x < y ? x : y);
      }
      for (var k = 0; k <= b.length; k++) {
        prev[k] = curr[k];
      }
    }
    return prev[b.length];
  }
}
