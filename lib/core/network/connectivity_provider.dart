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
/// Behaves identically on Android and iOS: the probe is a plain HTTPS request
/// via dart:io, which needs no extra permissions on either platform.
class ConnectivityNotifier extends Notifier<ConnectivityStatus> {
  static const _probeInterval = Duration(seconds: 12);
  static const _probeTimeout = Duration(seconds: 5);

  /// Lightweight, highly-available "captive portal" endpoints that answer an
  /// empty `204 No Content`. We probe over HTTPS (not just DNS) so a network
  /// where names resolve but real HTTPS egress is blocked — captive portal,
  /// firewalled hotspot — is correctly reported offline, matching the HTTPS
  /// traffic the gated STT/Gemini calls actually need. Multiple providers so a
  /// single outage can't produce a false "offline".
  static const _probeUrls = [
    'https://clients3.google.com/generate_204',
    'https://cp.cloudflare.com/generate_204',
  ];

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _timer;

  /// Guards against overlapping probes (a periodic tick landing while an
  /// interface-change probe is still in flight).
  bool _probing = false;

  /// Set when a refresh is requested while one is already running. The in-flight
  /// probe re-runs on completion instead of dropping the request — otherwise a
  /// network change landing mid-probe could leave the published state stale
  /// until the next periodic tick.
  bool _refreshQueued = false;

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

  /// Probe reachability and publish the resulting status. If called while a
  /// probe is already running, the request is queued so the in-flight probe
  /// re-runs once — this way a change that arrives mid-probe is never lost.
  Future<void> _refresh() async {
    if (_probing) {
      _refreshQueued = true;
      return;
    }
    _probing = true;
    try {
      do {
        _refreshQueued = false;
        final results = await _connectivity.checkConnectivity();
        if (results.every((r) => r == ConnectivityResult.none)) {
          state = ConnectivityStatus.offline;
        } else {
          final reachable = await _hasInternet();
          state = reachable
              ? ConnectivityStatus.online
              : ConnectivityStatus.offline;
        }
      } while (_refreshQueued);
    } finally {
      _probing = false;
    }
  }

  /// True if the internet is genuinely reachable. A successful HTTPS request to
  /// any probe endpoint proves we have real upstream egress (DNS + TCP + TLS +
  /// HTTP), not just a resolvable-but-dead network.
  Future<bool> _hasInternet() async {
    final client = HttpClient()..connectionTimeout = _probeTimeout;
    try {
      for (final url in _probeUrls) {
        try {
          final request = await client
              .getUrl(Uri.parse(url))
              .timeout(_probeTimeout);
          final response = await request.close().timeout(_probeTimeout);
          // Drain the (empty) body so the socket can be reused/closed cleanly.
          await response.drain<void>();
          // Must be *exactly* 204: a captive portal answers the same URL with a
          // 200 login page (or redirects to one), so accepting 200 would let a
          // portal masquerade as real internet.
          if (response.statusCode == 204) {
            return true;
          }
        } on SocketException {
          // Try the next endpoint.
        } on HttpException {
          // Try the next endpoint.
        } on TimeoutException {
          // Try the next endpoint.
        }
      }
      return false;
    } finally {
      client.close(force: true);
    }
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
