import 'package:flutter_test/flutter_test.dart';
import 'package:fixvia/core/validators.dart';

void main() {
  group('mobile', () {
    test('accepts 10 to 12 digits', () {
      expect(Validators.mobile('9876543210'), isNull);
      expect(Validators.mobile('09876543210'), isNull);
      expect(Validators.mobile('919876543210'), isNull);
    });

    test('strips formatting before counting', () {
      expect(Validators.mobile('+91 98765 43210'), isNull);
      expect(Validators.mobile('(080) 4111-2222'), isNull);
      expect(Validators.mobile('98765-43210'), isNull);
    });

    test('rejects short, long, and empty', () {
      expect(Validators.mobile('123456789'), equals('invalid_mobile'));
      expect(Validators.mobile('123'), equals('invalid_mobile'));
      expect(Validators.mobile('9198765432101'), equals('invalid_mobile'));
      expect(Validators.mobile(''), equals('invalid_mobile'));
      expect(Validators.mobile('abcdefghij'), equals('invalid_mobile'));
    });
  });

  group('otp', () {
    test('accepts exactly six digits', () {
      expect(Validators.otp('123456'), isNull);
      expect(Validators.otp('000000'), isNull);
    });

    test('rejects anything else', () {
      for (final bad in [
        '',
        '12',
        '12345',
        '1234567',
        '12345a',
        'abcdef',
        ' 123456',
        '123456 ',
        '123-456',
      ]) {
        expect(Validators.otp(bad), equals('invalid_otp'), reason: bad);
      }
    });
  });

  group('pincode', () {
    test('accepts exactly six digits', () {
      expect(Validators.pincode('682001'), isNull);
    });

    test('rejects anything else with its own code', () {
      for (final bad in ['', '68', '68201', '6820011', '68200a']) {
        expect(Validators.pincode(bad), equals('invalid_pincode'), reason: bad);
      }
    });
  });

  group('featuredRankOk', () {
    test('accepts 1-5 unique, ignoring nulls', () {
      expect(Validators.featuredRankOk([1, 2, 3, 4, 5]), isTrue);
      expect(Validators.featuredRankOk([3]), isTrue);
      expect(Validators.featuredRankOk([1, null, 2]), isTrue);
      expect(Validators.featuredRankOk([]), isTrue);
      expect(Validators.featuredRankOk([null, null]), isTrue);
    });

    test('rejects duplicates and out-of-range ranks', () {
      expect(Validators.featuredRankOk([1, 1]), isFalse);
      expect(Validators.featuredRankOk([1, null, 1]), isFalse);
      expect(Validators.featuredRankOk([0, 1]), isFalse);
      expect(Validators.featuredRankOk([1, 6]), isFalse);
      expect(Validators.featuredRankOk([-1]), isFalse);
      expect(Validators.featuredRankOk([1, 2, 3, 4, 5, 5]), isFalse);
    });
  });
}
