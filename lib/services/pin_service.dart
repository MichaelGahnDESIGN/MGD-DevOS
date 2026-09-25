import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gespeicherte PIN-Daten: nur Salz und Hash, niemals die PIN selbst.
@immutable
class PinRecord {
  const PinRecord({required this.length, required this.salt, required this.hash, required this.iterations});

  final int length;
  final String salt;
  final String hash;
  final int iterations;

  Map<String, Object> toJson() => {'len': length, 'salt': salt, 'hash': hash, 'iter': iterations};

  static PinRecord? fromJson(String? raw) {
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return PinRecord(length: m['len'] as int, salt: m['salt'] as String, hash: m['hash'] as String, iterations: m['iter'] as int);
    } catch (_) {
      return null; // Beschädigter Eintrag gilt als "keine PIN", statt die App dauerhaft zu sperren.
    }
  }
}

/// PIN-Sichtschutz beim Start (4, 6 oder 8 Ziffern).
///
/// Nur ein Sichtschutz gegen neugierige Blicke, keine Zugriffssicherung: PBKDF2-HMAC-SHA-256 mit
/// zufälligem Salz, gespeichert wird nur der Hash in den lokalen App-Einstellungen. Wer Zugriff auf
/// das Benutzerkonto oder die Dateien hat, kann die Einstellungen löschen und die Projektdateien
/// direkt lesen. Es gibt keine automatische Sperre bei Inaktivität. Ersetzt nicht die Anmeldung am
/// Rechner oder eine Festplattenverschlüsselung und verschlüsselt keine Projektdateien.
class PinService {
  PinService({Random? random}) : _random = random ?? Random.secure();

  static const allowedLengths = [4, 6, 8];
  static const iterations = 120000;
  static const _keyPin = 'app_pin_v1';
  static const _keyFails = 'app_pin_fails_v1';
  static const maxFreeAttempts = 5;

  final Random _random;

  static bool isValid(String pin, int length) =>
      allowedLengths.contains(length) && RegExp('^\\d{$length}\$').hasMatch(pin);

  Future<PinRecord?> read() async => PinRecord.fromJson((await SharedPreferences.getInstance()).getString(_keyPin));

  /// Legt eine neue PIN fest. Ist schon eine gesetzt, muss [current] stimmen.
  Future<void> setPin(String pin, int length, {String? current}) async {
    if (!isValid(pin, length)) throw ArgumentError('PIN muss genau $length Ziffern haben');
    final existing = await read();
    if (existing != null && (current == null || !await verify(current))) {
      throw StateError('Aktuelle PIN ist falsch');
    }
    final salt = base64Encode(List<int>.generate(16, (_) => _random.nextInt(256)));
    final hash = await compute(_derive, _DeriveArgs(pin, salt, iterations));
    final record = PinRecord(length: length, salt: salt, hash: hash, iterations: iterations);
    await (await SharedPreferences.getInstance()).setString(_keyPin, jsonEncode(record.toJson()));
  }

  /// Entfernt die PIN, nur mit richtiger aktueller PIN.
  Future<void> disable(String current) async {
    if (!await verify(current)) throw StateError('Aktuelle PIN ist falsch');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPin);
    await prefs.remove(_keyFails);
  }

  Future<bool> verify(String pin) async {
    final r = await read();
    if (r == null) return true;
    if (!isValid(pin, r.length)) return false;
    final hash = await compute(_derive, _DeriveArgs(pin, r.salt, r.iterations));
    return constantTimeEquals(hash, r.hash);
  }

  /// Wartezeit nach Fehlversuchen: ab dem 5. Fehlversuch 30 s, danach verdoppelt, höchstens 1 Stunde.
  Future<Duration> remainingLockout() async {
    final f = await _fails();
    final until = DateTime.fromMillisecondsSinceEpoch(f.$2);
    final left = until.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  /// Prüft beim Entsperren und zählt Fehlversuche mit.
  Future<bool> unlock(String pin) async {
    if (await remainingLockout() > Duration.zero) return false;
    final ok = await verify(pin);
    final prefs = await SharedPreferences.getInstance();
    if (ok) {
      await prefs.remove(_keyFails);
      return true;
    }
    final n = (await _fails()).$1 + 1;
    final until = n >= maxFreeAttempts
        ? DateTime.now().add(lockoutFor(n)).millisecondsSinceEpoch
        : 0;
    await prefs.setString(_keyFails, '$n:$until');
    return false;
  }

  static Duration lockoutFor(int fails) {
    if (fails < maxFreeAttempts) return Duration.zero;
    final seconds = 30 * pow(2, fails - maxFreeAttempts);
    return Duration(seconds: min(seconds.toInt(), 3600));
  }

  Future<(int, int)> _fails() async {
    final raw = (await SharedPreferences.getInstance()).getString(_keyFails);
    final parts = raw?.split(':');
    if (parts == null || parts.length != 2) return (0, 0);
    return (int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0);
  }
}

/// Vergleich ohne frühen Abbruch, damit die Laufzeit nichts über den Hash verrät.
bool constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;
  var r = 0;
  for (var i = 0; i < a.length; i++) {
    r |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return r == 0;
}

class _DeriveArgs {
  const _DeriveArgs(this.pin, this.salt, this.iterations);
  final String pin;
  final String salt;
  final int iterations;
}

String _derive(_DeriveArgs a) => pbkdf2Sha256(utf8.encode(a.pin), base64Decode(a.salt), a.iterations);

/// PBKDF2-HMAC-SHA-256 mit 32 Byte Ausgabe (RFC 8018), als Hex-Text.
@visibleForTesting
String pbkdf2Sha256(List<int> password, List<int> salt, int iterations) {
  final hmac = Hmac(sha256, password);
  final block = Uint8List.fromList([...salt, 0, 0, 0, 1]);
  var u = hmac.convert(block).bytes;
  final t = Uint8List.fromList(u);
  for (var i = 1; i < iterations; i++) {
    u = hmac.convert(u).bytes;
    for (var j = 0; j < t.length; j++) {
      t[j] ^= u[j];
    }
  }
  return t.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
