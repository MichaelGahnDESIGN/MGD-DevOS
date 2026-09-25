import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Sperrbildschirm beim Start, wenn eine PIN gesetzt ist. Zeigt die App-Version.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _controller = TextEditingController();
  String? _message;
  bool _busy = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _showLockout();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showLockout() async {
    final left = await widget.appState.pin.remainingLockout();
    if (!mounted) return;
    _tick?.cancel();
    if (left > Duration.zero) {
      setState(() => _message = 'Zu viele Fehlversuche. Bitte ${left.inSeconds + 1} s warten.');
      _tick = Timer(const Duration(seconds: 1), _showLockout);
    } else if (_message != null && _message!.startsWith('Zu viele')) {
      setState(() => _message = null);
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    // Während der Wartezeit gar nicht prüfen, sonst erschiene auch eine richtige PIN als "falsch".
    if (await widget.appState.pin.remainingLockout() > Duration.zero) return _showLockout();
    if (!mounted) return;
    setState(() => _busy = true);
    final ok = await widget.appState.unlock(_controller.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!ok) {
        _controller.clear();
        _message = 'Falsche PIN.';
      }
    });
    if (!ok) await _showLockout();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final len = widget.appState.pinLength ?? 8;
    return Scaffold(
      body: Center(
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(Space.xxl),
          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(Radii.lg), border: Border.all(color: c.border)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandMark(size: 44),
              const SizedBox(height: Space.md),
              Text('MGD-DevOS ist gesperrt', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: Space.xs),
              Text('Version ${widget.appState.meta.label}', style: TextStyle(fontSize: 12.5, color: c.muted)),
              const SizedBox(height: Space.xl),
              TextField(
                controller: _controller,
                autofocus: true,
                obscureText: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: len,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 22, letterSpacing: 10, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(counterText: '', hintText: 'PIN'),
                onSubmitted: (_) => _submit(),
              ),
              if (_message != null) ...[
                const SizedBox(height: Space.sm),
                Text(_message!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
              ],
              const SizedBox(height: Space.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Entsperren'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
