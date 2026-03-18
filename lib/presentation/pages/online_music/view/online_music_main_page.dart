import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:open_player/base/db/hive_service.dart';

class OnlineMusicMainPage extends StatefulWidget {
  const OnlineMusicMainPage({super.key});

  @override
  State<OnlineMusicMainPage> createState() => _OnlineMusicMainPageState();
}

class _OnlineMusicMainPageState extends State<OnlineMusicMainPage>
    with AutomaticKeepAliveClientMixin {
  // ── Keep alive so WebView doesn't reload on tab switch ─────────────────────
  @override
  bool get wantKeepAlive => true;

  // ── Constants ──────────────────────────────────────────────────────────────
  static const String _siteUrl = 'https://hayasaka.8man.in/';
  static const String _siteDomain = 'hayasaka.8man.in';
  static const Color _bg = Color(0xFF0F0F1A);
  static const Color _surface = Color(0xFF1A1A2E);
  static const Color _accent = Color(0xFF6C63FF);

  // ── State ──────────────────────────────────────────────────────────────────
  InAppWebViewController? _wvc;
  bool _loaded = false;
  bool _hasError = false;
  bool _isOffline = false;
  double _progress = 0;
  bool _canGoBack = false;
  StreamSubscription? _connectSub;

  // ── WebView settings ───────────────────────────────────────────────────────
  final InAppWebViewSettings _settings = InAppWebViewSettings(
    javaScriptEnabled: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    hardwareAcceleration: true,
    useHybridComposition: true,
    cacheEnabled: true,
    clearCache: false,
    domStorageEnabled: true,
    databaseEnabled: true,
    thirdPartyCookiesEnabled: true,
    allowContentAccess: true,
    allowFileAccess: true,
    mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
    supportZoom: false,
    transparentBackground: true,
    disableDefaultErrorPage: true,
    verticalScrollBarEnabled: false,
    horizontalScrollBarEnabled: false,
    overScrollMode: OverScrollMode.IF_CONTENT_SCROLLS,
    useWideViewPort: true,
    loadWithOverviewMode: true,
    javaScriptCanOpenWindowsAutomatically: false,
    supportMultipleWindows: false,
    userAgent: 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/125.0.6422.165 Mobile Safari/537.36',
  );

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectSub = Connectivity().onConnectivityChanged.listen((results) {
      final offline = _isOffline_(results);
      if (mounted && offline != _isOffline) {
        setState(() => _isOffline = offline);
        // Auto-reload when connection is restored
        if (!offline && _hasError) _retry();
      }
    });

    // Show disclaimer once across the entire app lifetime
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowDisclaimer());
  }

  @override
  void dispose() {
    _connectSub?.cancel();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool _isOffline_(dynamic r) {
    if (r is List<ConnectivityResult>) {
      return r.isEmpty || r.every((e) => e == ConnectivityResult.none);
    }
    return r == ConnectivityResult.none;
  }

  Future<void> _checkConnectivity() async {
    final r = await Connectivity().checkConnectivity();
    if (mounted) setState(() => _isOffline = _isOffline_(r));
  }

  Future<void> _checkConnectivityAndSetError() async {
    final r = await Connectivity().checkConnectivity();
    if (mounted)
      setState(() {
        _hasError = true;
        _isOffline = _isOffline_(r);
      });
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _loaded = false;
      _progress = 0;
    });
    _wvc?.reload();
  }

  Future<void> _goBack() async {
    if (_wvc != null && _canGoBack) await _wvc!.goBack();
  }

  // Show disclaimer only once — persisted in Hive
  void _maybeShowDisclaimer() {
    final alreadyShown = MyHiveBoxes.user
        .get(MyHiveKeys.onlineMusicDialogShown, defaultValue: false) as bool;
    if (alreadyShown) return;

    MyHiveBoxes.user.put(MyHiveKeys.onlineMusicDialogShown, true);
    _showDisclaimer();
  }

  void _showDisclaimer() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _accent.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: -8,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.music_note_rounded,
                    color: _accent, size: 30),
              ),

              const SizedBox(height: 16),

              const Text('Online Music',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  )),

              const SizedBox(height: 12),

              const Text(
                'Enjoy free music streaming via our integrated web player.\n\n'
                '🚧  Our own online music system is coming soon!\n\n'
                'This is a temporary experience while we build something amazing.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                  height: 1.6,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Got it!',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context); // required for AutomaticKeepAliveClientMixin

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: !_canGoBack,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _goBack();
        },
        child: Container(
          color: _bg,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Top bar ────────────────────────────────────────────────
                _TopBar(
                  canGoBack: _canGoBack,
                  onBack: _goBack,
                  onReload: _retry,
                  isLoading: !_loaded && !_hasError,
                  progress: _progress,
                ),

                // ── WebView ────────────────────────────────────────────────
                Expanded(
                  child: Stack(
                    children: [
                      // Web view — always in tree to avoid full reload on errors
                      Opacity(
                        opacity:
                            (_hasError || (_isOffline && _wvc == null)) ? 0 : 1,
                        child: InAppWebView(
                          initialUrlRequest: URLRequest(url: WebUri(_siteUrl)),
                          initialSettings: _settings,
                          onWebViewCreated: (c) => _wvc = c,
                          onLoadStart: (_, __) {
                            if (mounted)
                              setState(() {
                                _loaded = false;
                                _hasError = false;
                              });
                          },
                          onLoadStop: (c, _) async {
                            // Inject viewport meta + clean up ads
                            await c.evaluateJavascript(source: '''
                              (function() {
                                // Remove unwanted elements
                                ['footer','.ads','.banner','.cookie-banner',
                                 '.popup','[class*="ad-"]','[id*="ad-"]']
                                  .forEach(s => document.querySelectorAll(s)
                                    .forEach(el => el.remove()));

                                // Ensure correct viewport
                                let m = document.querySelector('meta[name="viewport"]');
                                if (!m) {
                                  m = document.createElement('meta');
                                  m.name = 'viewport';
                                  document.head.appendChild(m);
                                }
                                m.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0';
                              })();
                            ''');

                            final back = await c.canGoBack();
                            if (mounted)
                              setState(() {
                                _loaded = true;
                                _canGoBack = back;
                              });
                          },
                          onProgressChanged: (_, p) {
                            if (mounted) setState(() => _progress = p / 100);
                          },
                          onUpdateVisitedHistory: (c, _, __) async {
                            final back = await c.canGoBack();
                            if (mounted) setState(() => _canGoBack = back);
                          },
                          onReceivedError: (_, req, __) {
                            if (req.isForMainFrame ?? false) {
                              _checkConnectivityAndSetError();
                            }
                          },
                          onReceivedHttpError: (_, req, res) {
                            if ((req.isForMainFrame ?? false) &&
                                (res.statusCode ?? 0) >= 400) {
                              _checkConnectivityAndSetError();
                            }
                          },
                          shouldOverrideUrlLoading: (_, action) async {
                            final url = action.request.url?.toString() ?? '';
                            // Allow the site + internal schemes
                            if (url.contains(_siteDomain) ||
                                url.startsWith('about:') ||
                                url.startsWith('data:') ||
                                url.startsWith('blob:') ||
                                url.startsWith('javascript:')) {
                              return NavigationActionPolicy.ALLOW;
                            }
                            // Allow necessary CDN / API hosts
                            final host =
                                Uri.tryParse(url)?.host.toLowerCase() ?? '';
                            if ([
                              'cdn',
                              'googleapis',
                              'gstatic',
                              'cloudflare',
                              'jsdelivr',
                              'unpkg'
                            ].any((h) => host.contains(h))) {
                              return NavigationActionPolicy.ALLOW;
                            }
                            // Block everything else (ads, external links)
                            return NavigationActionPolicy.CANCEL;
                          },
                        ),
                      ),

                      // Loading overlay
                      if (!_loaded && !_hasError)
                        _LoadingOverlay(
                            progress: _progress, accent: _accent, bg: _bg),

                      // Error / offline overlay
                      if (_hasError)
                        _ErrorOverlay(
                          isOffline: _isOffline,
                          accent: _accent,
                          bg: _bg,
                          onRetry: _retry,
                          onOfflineHint: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Switch to the audio tab to listen offline'),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TOP BAR
// ═══════════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.canGoBack,
    required this.onBack,
    required this.onReload,
    required this.isLoading,
    required this.progress,
  });

  final bool canGoBack;
  final VoidCallback onBack, onReload;
  final bool isLoading;
  final double progress;

  static const Color _surface = Color(0xFF16213E);
  static const Color _accent = Color(0xFF6C63FF);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: const BoxDecoration(
            color: _surface,
            border: Border(
              bottom: BorderSide(color: Colors.white10, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              // Back
              IconButton(
                onPressed: canGoBack ? onBack : null,
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: canGoBack ? Colors.white : Colors.white24,
                  size: 20,
                ),
              ),

              // Title
              const Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.music_note_rounded, color: _accent, size: 18),
                    SizedBox(width: 6),
                    Text('Online Music',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        )),
                    SizedBox(width: 6),
                    // "Coming soon" badge
                    _Badge(),
                  ],
                ),
              ),

              // Reload
              IconButton(
                onPressed: onReload,
                icon: const Icon(Icons.refresh_rounded,
                    color: Colors.white70, size: 22),
              ),
            ],
          ),
        ),

        // Thin progress line under the bar
        if (isLoading)
          LinearProgressIndicator(
            value: progress > 0 ? progress : null,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation<Color>(_accent),
            minHeight: 2,
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
          border:
              Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.4)),
        ),
        child: const Text('Beta',
            style: TextStyle(
              color: Color(0xFF6C63FF),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            )),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// LOADING OVERLAY
// ═══════════════════════════════════════════════════════════════════════════════

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay({
    required this.progress,
    required this.accent,
    required this.bg,
  });

  final double progress;
  final Color accent, bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pulsing icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.85, end: 1.0),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeInOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.15),
                ),
                child: Icon(Icons.music_note_rounded, color: accent, size: 36),
              ),
            ),

            const SizedBox(height: 28),

            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            const Text('Loading music player…',
                style: TextStyle(color: Colors.white38, fontSize: 14)),

            const SizedBox(height: 28),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 64),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress > 0 ? progress : null,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                  minHeight: 5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ERROR OVERLAY
// ═══════════════════════════════════════════════════════════════════════════════

class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({
    required this.isOffline,
    required this.accent,
    required this.bg,
    required this.onRetry,
    required this.onOfflineHint,
  });

  final bool isOffline;
  final Color accent, bg;
  final VoidCallback onRetry, onOfflineHint;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOffline ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
                size: 72,
                color: Colors.white24,
              ),
              const SizedBox(height: 20),
              Text(
                isOffline ? 'You\'re Offline' : 'Something Went Wrong',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isOffline
                    ? 'Check your Wi-Fi or mobile data and try again.'
                    : 'The music player couldn\'t load. Tap retry to try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white38,
                  height: 1.6,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Retry',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                ),
              ),
              if (isOffline) ...[
                const SizedBox(height: 14),
                TextButton(
                  onPressed: onOfflineHint,
                  child: const Text('Listen Offline Instead',
                      style: TextStyle(color: Colors.white30, fontSize: 13)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
