import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// ChangeNotifier seguro para Flutter web.
///
/// En Flutter web, `MouseTracker.updateAllDevices` corre como persistent frame
/// callback. Si un provider llama `notifyListeners()` durante ese callback
/// (p.ej. al completar una petición async), el widget tree se reconstruye
/// agregando RenderBox sin layout, disparando:
///   - "Cannot hit test a render box that has never been laid out"
///   - "!_debugDuringDeviceUpdate"
///
/// Esta clase difiere la notificación a post-frame cuando se está en una
/// fase activa del scheduler, evitando render boxes sin layout durante hit-test.
abstract class SafeChangeNotifier extends ChangeNotifier {
  bool _pendingNotify = false;

  @override
  void notifyListeners() {
    if (!kIsWeb) {
      super.notifyListeners();
      return;
    }
    final phase = SchedulerBinding.instance.schedulerPhase;
    final inFrame = phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.transientCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks;

    if (inFrame) {
      // Defer to post-frame so layout completes before hit-testing
      debugPrint('[SafeNotify] deferred — phase=$phase (${runtimeType})');
      if (!_pendingNotify) {
        _pendingNotify = true;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _pendingNotify = false;
          if (hasListeners) notifyListeners();
        });
      }
    } else {
      super.notifyListeners();
    }
  }
}
