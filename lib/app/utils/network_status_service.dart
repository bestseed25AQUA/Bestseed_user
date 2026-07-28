import 'dart:async';

import 'package:internet_connection_checker/internet_connection_checker.dart';

// Active network reachability monitor. Unlike `connectivity_plus`, which
// reports the OS-level interface state and is unreliable on some devices
// (e.g. doesn't emit on airplane-mode toggle), this service actually probes
// a reachable host every few seconds. It's the source of truth for "am I
// really online?", regardless of what the OS thinks.
//
// Single global instance shared by all video tiles so probe traffic is
// bounded to one request per interval no matter how many widgets subscribe.
class NetworkStatusService {
  NetworkStatusService._() {
    _timer = Timer.periodic(_pollInterval, (_) => _probe());
    _probe();
  }
  static final NetworkStatusService instance = NetworkStatusService._();

  static const Duration _pollInterval = Duration(seconds: 3);
  static const Duration _probeTimeout = Duration(seconds: 3);

  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  Timer? _timer;
  bool _lastKnown = true;
  bool _probing = false;

  Stream<bool> get onStatusChange => _controller.stream;
  bool get isOnline => _lastKnown;

  Future<void> _probe() async {
    if (_probing) return;
    _probing = true;
    bool online = false;
    try {
      online = await InternetConnectionChecker.createInstance()
          .hasConnection
          .timeout(_probeTimeout, onTimeout: () => false);
    } catch (_) {
      online = false;
    }
    _probing = false;
    if (online != _lastKnown) {
      _lastKnown = online;
      _controller.add(online);
    }
  }
}
