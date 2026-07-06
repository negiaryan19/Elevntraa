import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Live connectivity of the device.
///
/// - [online]  — connected to a network AND real internet is reachable.
/// - [offline] — no network, or a network with no working internet (captive
///   portal, dead router, airplane mode).
/// - [checking] — the very first reachability probe hasn't returned yet.
enum ConnectivityStatus { online, offline, checking }

/// Watches network interface changes via `connectivity_plus` and, crucially,
/// verifies that the internet is *actually* reachable rather than trusting the
/// "connected to WiFi/mobile" signal alone — a phone can be on WiFi behind a
/// captive portal or a router with no upstream and still have no internet.
///
/// Reachability is re-checked:
///  * immediately whenever the OS reports an interface change, and
///  * on a periodic timer ([_probeInterval]) to catch silent losses (router
///    dies, data pack exhausted) that don't flip the interface state.
///
/// Behaves identically on Android and iOS: the probe is a plain DNS lookup via
/// dart:io, which needs no extra permissions on either platform.
class ConnectivityNotifier extends Notifier<ConnectivityStatus> {
  static const _probeInterval = Duration(seconds: 12);
  static const _probeTimeout = Duration(seconds: 5);

  /// Hosts we DNS-resolve to prove the internet works. Multiple well-known,
  /// highly-available anycast resolvers so a single provider outage doesn't
  /// make us report a false "offline".
  static const _probeHosts = ['one.one.one.one', 'dns.google', 'google.com'];

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _timer;

  /// Guards against overlapping probes (a periodic tick landing while an
  /// interface-change probe is still in flight).
  bool _probing = false;

  @override
  ConnectivityStatus build() {
    _sub = _connectivity.onConnectivityChanged.listen(_onInterfaceChanged);
    _timer = Timer.periodic(_probeInterval, (_) => _refresh());
    ref.onDispose(() {
      _sub?.cancel();
      _timer?.cancel();
    });

    // Kick off the first probe; state stays [checking] until it resolves.
    _refresh();
    return ConnectivityStatus.checking;
  }

  Future<void> _onInterfaceChanged(List<ConnectivityResult> results) async {
    // No interface at all — definitively offline, skip the (pointless) probe.
    if (results.every((r) => r == ConnectivityResult.none)) {
      state = ConnectivityStatus.offline;
      return;
    }
    await _refresh();
  }

  /// Probe reachability and publish the resulting status.
  Future<void> _refresh() async {
    if (_probing) return;
    _probing = true;
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.every((r) => r == ConnectivityResult.none)) {
        state = ConnectivityStatus.offline;
        return;
      }
      final reachable = await _hasInternet();
      state = reachable
          ? ConnectivityStatus.online
          : ConnectivityStatus.offline;
    } finally {
      _probing = false;
    }
  }

  /// True if the internet is genuinely reachable. A DNS lookup succeeding
  /// against any probe host proves we have real upstream connectivity, not
  /// just an associated-but-dead network.
  Future<bool> _hasInternet() async {
    for (final host in _probeHosts) {
      try {
        final result = await InternetAddress.lookup(
          host,
        ).timeout(_probeTimeout);
        if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
          return true;
        }
      } on SocketException {
        // Try the next host.
      } on TimeoutException {
        // Try the next host.
      }
    }
    return false;
  }

  /// Force an immediate reachability re-check (e.g. after a user retries a
  /// blocked action). Safe to call from the UI.
  Future<void> recheck() => _refresh();
}

/// App-wide connectivity status. Watch this from any screen to react to the
/// device going on/offline; it drives the header indicator and gates any
/// action that needs the server (STT / Gemini / uploads).
final connectivityStatusProvider =
    NotifierProvider<ConnectivityNotifier, ConnectivityStatus>(
      ConnectivityNotifier.new,
    );
