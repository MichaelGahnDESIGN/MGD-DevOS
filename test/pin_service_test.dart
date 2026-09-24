import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mgd_devos/services/pin_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('PBKDF2-HMAC-SHA-256 entspricht den Testvektoren (RFC 7914, Abschnitt 11)', () {
    expect(pbkdf2Sha256('password'.codeUnits, 'salt'.codeUnits, 1),
        '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b');
    expect(pbkdf2Sha256('password'.codeUnits, 'salt'.codeUnits, 2),
        'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43');
  });

  test('Nur 4, 6 oder 8 Ziffern sind gültig', () {
    expect(PinService.isValid('1234', 4), isTrue);
    expect(PinService.isValid('123456', 6), isTrue);
    expect(PinService.isValid('12345678', 8), isTrue);
    expect(PinService.isValid('12345', 5), isFalse);
    expect(PinService.isValid('12a4', 4), isFalse);
    expect(PinService.isValid('123', 4), isFalse);
  });

  test('PIN setzen, prüfen, nur mit aktueller PIN ändern und deaktivieren', () async {
    final s = PinService();
    expect(await s.read(), isNull);
    await s.setPin('1234', 4);
    final r = await s.read();
    expect(r!.length, 4);
    expect(r.hash, isNot(contains('1234')));
    expect(await s.verify('1234'), isTrue);
    expect(await s.verify('4321'), isFalse);

    expect(() => s.setPin('123456', 6), throwsStateError);
    expect(() => s.setPin('123456', 6, current: '0000'), throwsStateError);
    await s.setPin('123456', 6, current: '1234');
    expect(await s.verify('123456'), isTrue);

    expect(() => s.disable('000000'), throwsStateError);
    await s.disable('123456');
    expect(await s.read(), isNull);
  });

  test('Wartezeit nach Fehlversuchen steigt und ist begrenzt', () async {
    expect(PinService.lockoutFor(4), Duration.zero);
    expect(PinService.lockoutFor(5), const Duration(seconds: 30));
    expect(PinService.lockoutFor(6), const Duration(seconds: 60));
    expect(PinService.lockoutFor(40), const Duration(hours: 1));

    final s = PinService();
    await s.setPin('1234', 4);
    for (var i = 0; i < 5; i++) {
      expect(await s.unlock('0000'), isFalse);
    }
    expect(await s.remainingLockout(), greaterThan(Duration.zero));
    expect(await s.unlock('1234'), isFalse, reason: 'Während der Wartezeit auch mit richtiger PIN gesperrt');
  });
}
