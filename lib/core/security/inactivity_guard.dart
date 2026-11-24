import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:tarlan_bank/core/router/pin_gate.dart';
import 'package:tarlan_bank/features/auth/providers/pin_gate_provider.dart';

import 'inactivity_tracker.dart';

/// Re-locks the PIN gate after [defaultInactivityTimeout] without interaction.
///
/// There is intentionally no background timer: a suspended or frozen isolate
/// cannot be relied on to fire Dart timers, and Android may freeze timers in
/// Doze. Instead the tracker records a wall-clock timestamp on every
/// interaction; the check runs on the foreground tick and again on resume.
/// Wall clock keeps advancing while the app is frozen, so a long background
/// gap is caught the moment the user returns.
class InactivityGuard extends ConsumerStatefulWidget {
  const InactivityGuard({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<InactivityGuard> createState() => _InactivityGuardState();
}

class _InactivityGuardState extends ConsumerState<InactivityGuard>
    with WidgetsBindingObserver {
  final InactivityTracker _tracker = InactivityTracker();
  ProviderSubscription<PinGateState>? _unlockSub;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tracker.recordActivity();
    WidgetsBinding.instance.addObserver(this);
    // Biometric unlock has no pointer event, so restart the window whenever
    // the gate transitions to unlocked. listenManual lives for the whole app
    // lifetime and is not re-subscribed on rebuild.
    _unlockSub = ref.listenManual(pinGateProvider, (previous, next) {
      if (next.status == PinGateStatus.unlocked &&
          previous?.status != PinGateStatus.unlocked) {
        _tracker.recordActivity();
      }
    });
    // Foreground only. Background/frozen gaps are handled by the resume
    // lifecycle callback, not by this timer.
    _tick = Timer.periodic(const Duration(seconds: 15), (_) => _check());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Do NOT reset the clock on background: the window is "no interaction",
    // not "time away from the app". Checking elapsed wall time on resume
    // catches a long background/frozen gap immediately.
    if (state == AppLifecycleState.resumed) _check();
  }

  void _check() {
    if (!mounted || !_tracker.isTimedOut) return;
    // Re-locking an already closed gate is pointless and would re-read secure
    // storage on every resume; the guard only cares about an open session.
    if (ref.read(pinGateProvider).status != PinGateStatus.unlocked) return;
    ref.read(pinGateProvider.notifier).relock();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _tracker.recordActivity(),
    onPointerMove: (_) => _tracker.recordActivity(),
    onPointerSignal: (_) => _tracker.recordActivity(),
    child: widget.child,
  );

  @override
  void dispose() {
    _tick?.cancel();
    _unlockSub?.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
