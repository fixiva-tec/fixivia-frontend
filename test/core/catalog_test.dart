import 'package:flutter_test/flutter_test.dart';
import 'package:fixvia/core/catalog.dart';

void main() {
  group('isBookableCategory', () {
    test('live slug books', () {
      expect(isBookableCategory('water-purifier-repair'), isTrue);
    });

    test('other slugs are coming soon', () {
      expect(isBookableCategory('ac-repair'), isFalse);
      expect(isBookableCategory('plumbing'), isFalse);
    });

    test('null and empty never book', () {
      expect(isBookableCategory(null), isFalse);
      expect(isBookableCategory(''), isFalse);
    });

    test('match is case-insensitive', () {
      expect(isBookableCategory('Water-Purifier-Repair'), isTrue);
    });
  });
}
