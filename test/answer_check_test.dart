import 'package:flutter_test/flutter_test.dart';
import 'package:kabyle_duo/utils/answer_check.dart';

void main() {
  group('AnswerCheck (forgiving)', () {
    test('exact match passes', () {
      expect(AnswerCheck.isAcceptable('soleil', 'soleil'), isTrue);
    });

    test('case and surrounding whitespace ignored', () {
      expect(AnswerCheck.isAcceptable('Soleil', '  soleil '), isTrue);
    });

    test('missing French accents still accepted', () {
      expect(AnswerCheck.isAcceptable('étoile', 'etoile'), isTrue);
      expect(AnswerCheck.isAcceptable('cœur', 'coeur'), isTrue);
    });

    test('missing Kabyle special letters still accepted', () {
      // azeggaɣ -> azeggag, taɣaṭ -> tagat, aḍar -> adar
      expect(AnswerCheck.isAcceptable('azeggaɣ', 'azeggag'), isTrue);
      expect(AnswerCheck.isAcceptable('taɣaṭ', 'tagat'), isTrue);
      expect(AnswerCheck.isAcceptable('aḍar', 'adar'), isTrue);
    });

    test('single-character typo in a longer word is tolerated', () {
      expect(AnswerCheck.isAcceptable('montagne', 'montaigne'), isTrue);
    });

    test('a clearly different word is rejected', () {
      expect(AnswerCheck.isAcceptable('soleil', 'lune'), isFalse);
      expect(AnswerCheck.isAcceptable('chien', 'chat'), isFalse);
    });

    test('short words require near-exact spelling', () {
      // "eau" (3 chars) tolerates only distance 1; "xyz" is too far.
      expect(AnswerCheck.isAcceptable('eau', 'xyz'), isFalse);
    });
  });
}
