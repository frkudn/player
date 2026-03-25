import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:gap/gap.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/base/db/hive_service.dart';
import 'package:open_player/presentation/features/online_section/cubit/online_section_cubit.dart';
import 'package:open_player/presentation/features/online_section/models/online_instance.dart';
import '../data/online_data_instances.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ONLINE SECTION PAGE
//
// Three-level navigation:
//   Level 0 — Explore grid (category cards)
//   Level 1 — Sites list   (all instances for a category)
//   Level 2 — Browser      (WebView for selected instance)
//
// Header budget:
//   Level 0/1 : 44 px top bar
//   Level 2   : 0–44 px collapsible top bar + 36 px instance chips = max 80 px
//               (top bar hides on swipe/tap, a 4-dp drag handle re-shows it)
//
// Back navigation:
//   Browser  → browser history back (if available) THEN sites list
//   Sites    → explore grid
//   Explore  → system back (exits the online tab)
//
// Extra features:
//   🛡 Advanced ad block (JS + URL level, MutationObserver + click hijack)
//   🌙 Background play (keepAlive WebView + wakelock via toggle)
//   🔄 Landscape unlock (rotates when in browser, reverts on exit)
//   👁 Top bar collapse (swipe up or tap handle to reveal)
// ─────────────────────────────────────────────────────────────────────────────

class OnlineSectionPage extends StatefulWidget {
  const OnlineSectionPage({super.key});
  @override
  State<OnlineSectionPage> createState() => _OnlineSectionPageState();
}

class _OnlineSectionPageState extends State<OnlineSectionPage>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true;

  // ── WebView ────────────────────────────────────────────────────────────────
  InAppWebViewController? _wvc;
  late final _keepAlive = InAppWebViewKeepAlive();

  bool _loaded = false;
  bool _hasError = false;
  bool _isOffline = false;
  double _progress = 0;
  bool _canGoBack = false;

  // Tracks if the user is in the middle of a gesture to reveal the top bar
  // (drag from the handle at the top of the browser area)
  double _revealDragDelta = 0;

  StreamSubscription? _connectSub;

  // ── WebView settings ───────────────────────────────────────────────────────
  final InAppWebViewSettings _wvSettings = InAppWebViewSettings(
    javaScriptEnabled: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    allowsAirPlayForMediaPlayback: true,
    hardwareAcceleration: true,
    useHybridComposition: true,
    cacheEnabled: true,
    domStorageEnabled: true,
    databaseEnabled: true,
    thirdPartyCookiesEnabled: true,
    allowContentAccess: true,
    allowFileAccess: true,
    mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
    supportZoom: true, // allow pinch-zoom on web pages
    transparentBackground: true,
    disableDefaultErrorPage: true,
    verticalScrollBarEnabled: false,
    horizontalScrollBarEnabled: false,
    overScrollMode: OverScrollMode.IF_CONTENT_SCROLLS,
    useWideViewPort: true,
    loadWithOverviewMode: true,
    javaScriptCanOpenWindowsAutomatically: false,
    supportMultipleWindows: false,
    // Keep media playing when app is in background (user must toggle this on)
    allowBackgroundAudioPlaying: true,
    userAgent:
        'Mozilla/5.0 (Linux; Android 14; Pixel 9 Pro) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/126.0.6478.122 Mobile Safari/537.36',
  );

  // ── ADVANCED AD-BLOCK SCRIPT ───────────────────────────────────────────────
  // Runs on every page load. Uses three layers:
  //   1. CSS injection — hides ad elements before they paint
  //   2. DOM removal   — removes ad nodes immediately and on mutations
  //   3. Event hijack  — cancels clicks on known tracker/redirect links
  static const String _adJS = r"""
(function(){
  'use strict';

  // ── Layer 1: CSS hide (instant, before paint) ─────────────────────────────
  const CSS = `
    .adsbygoogle,ins.adsbygoogle,.dfp-tag,.gpt-ad,
    [class*="advert"],[id*="advert"],
    [class*="ads-"],[class*="-ads"],[id*="ads-"],[id*="-ads"],
    [class*=" ad "],[class*="-ad-"],[id*="-ad-"],
    [class*="banner"],[id*="banner"],
    [class*="sponsor"],[id*="sponsor"],
    [class*="cookie-"],[id*="cookie-"],[class*="gdpr"],[id*="gdpr"],
    [class*="consent"],[id*="consent"],
    [class*="notice"][class*="cookie"],
    [class*="popup"],[id*="popup"],
    [class*="interstitial"],[id*="interstitial"],
    [class*="overlay"][class*="ad"],[id*="overlay"][id*="ad"],
    .taboola-widget,.outbrain-widget,.mgid-widget,
    [data-taboola-widget],[data-outbrain],[data-mgid],
    iframe[src*="doubleclick"],iframe[src*="googlesyndication"],
    iframe[src*="adservice"],iframe[src*="amazon-adsystem"],
    iframe[src*="moatads"],iframe[src*="scorecardresearch"],
    iframe[src*="pubmatic"],iframe[src*="rubiconproject"],
    div[id^="div-gpt-ad"],div[id*="google_ads"] {
      display:none!important;
      visibility:hidden!important;
      opacity:0!important;
      height:0!important;
      overflow:hidden!important;
      pointer-events:none!important;
    }
  `;
  try {
    const s = document.createElement('style');
    s.textContent = CSS;
    (document.head||document.documentElement).appendChild(s);
  } catch(_){}

  // ── Layer 2: DOM removal ──────────────────────────────────────────────────
  const SELECTORS = [
    '.adsbygoogle','ins.adsbygoogle',
    '[class*="advert"],[id*="advert"]',
    '[class*="ads-"],[class*="-ads"],[id*="ads-"]',
    '[class*="banner"],[id*="banner"]',
    '[class*="cookie-"],[id*="cookie-"],[class*="gdpr"],[class*="consent"]',
    '[class*="popup"],[id*="popup"]',
    '[class*="interstitial"],[id*="interstitial"]',
    '.taboola-widget,.outbrain-widget',
    '[data-taboola-widget],[data-outbrain]',
    'iframe[src*="doubleclick"],iframe[src*="googlesyndication"]',
    'iframe[src*="adservice"],iframe[src*="amazon-adsystem"]',
    '[class*="newsletter-popup"],[id*="newsletter"]',
    '[class*="modal"][class*="ad"],[id*="modal"][id*="ad"]',
    '[class*="overlay"]:not([class*="video"]):not([id*="player"]):not([class*="player"])',
    'div[id^="div-gpt-ad"],div[id*="google_ads"]',
  ].join(',');

  // Safe remove — never touch video/player wrappers
  const safeRemove = el => {
    if (!el) return;
    if (el.closest('[id*="player"],[class*="player"],[class*="video"],[data-player]')) return;
    el.remove();
  };

  const sweep = () => {
    try { document.querySelectorAll(SELECTORS).forEach(safeRemove); } catch(_){}
  };

  sweep();
  const mo = new MutationObserver(()=>{ sweep(); });
  mo.observe(document.documentElement,{childList:true,subtree:true,attributes:true});

  // ── Layer 3: Kill popups / new-tab tricks ─────────────────────────────────
  window.open  = ()=>null;
  window.alert = ()=>{};
  window.confirm = ()=>false;
  window.prompt  = ()=>null;

  // Cancel clicks leading to known ad-redirect patterns
  const AD_PATTERNS = [
    /\/(click|track|redirect|aff|affiliate|out)\//i,
    /[?&](utm_|ref=|aff_|affiliate)/i,
  ];
  document.addEventListener('click', e => {
    const a = e.target.closest('a[href]');
    if (!a) return;
    const href = a.href || '';
    if (AD_PATTERNS.some(p => p.test(href))) {
      e.preventDefault(); e.stopPropagation();
    }
  }, {capture:true, passive:false});

  // ── Layer 4: Block annoying auto-redirect timers ──────────────────────────
  const _origSetInterval = window.setInterval;
  const _origSetTimeout  = window.setTimeout;
  const BLOCK_RE = /popup|overlay|modal|redirect|advert/i;
  window.setInterval = (fn, ms, ...args) => {
    try { if (BLOCK_RE.test(fn.toString())) return 0; } catch(_){}
    return _origSetInterval(fn, ms, ...args);
  };
  window.setTimeout = (fn, ms, ...args) => {
    try { if (ms < 1500 && BLOCK_RE.test(fn.toString())) return 0; } catch(_){}
    return _origSetTimeout(fn, ms, ...args);
  };

})();
""";

  // URL-level ad domain blocklist
  static const Set<String> _adDomains = {
    'googlesyndication.com',
    'doubleclick.net',
    'adservice.google.com',
    'googletagmanager.com',
    'adnxs.com',
    'amazon-adsystem.com',
    'outbrain.com',
    'taboola.com',
    'revcontent.com',
    'criteo.com',
    'pubmatic.com',
    'rubiconproject.com',
    'openx.net',
    'appnexus.com',
    'moatads.com',
    'scorecardresearch.com',
    'serving-sys.com',
    'mgid.com',
    'propellerads.com',
    'popads.net',
    'popcash.net',
    'trafficjunky.com',
    'exoclick.com',
    'juicyads.com',
    'adsterra.com',
    'hilltopads.net',
    'adcash.com',
    'bidvertiser.com',
    'clickadu.com',
  };

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkConnectivity();
    _connectSub = Connectivity().onConnectivityChanged.listen((r) {
      final off = _parseOffline(r);
      if (mounted && off != _isOffline) {
        setState(() => _isOffline = off);
        if (!off && _hasError) _retry();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeDisclaimer());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectSub?.cancel();
    // Restore portrait and nav bar
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    context.read<OnlineSectionCubit>().showNavBar();
    super.dispose();
  }

  // Handle app going to background — respect background play toggle
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final cubitState = context.read<OnlineSectionCubit>().state;
    if (state == AppLifecycleState.paused &&
        !cubitState.isBackgroundPlayEnabled) {
      // pause any media
      _wvc?.evaluateJavascript(
          source:
              'document.querySelectorAll("audio,video").forEach(v=>v.pause())');
    }
  }

  // ── Orientation ────────────────────────────────────────────────────────────

  void _applyOrientation(bool landscape) {
    if (landscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  // ── Connectivity ───────────────────────────────────────────────────────────

  bool _parseOffline(dynamic r) {
    if (r is List<ConnectivityResult>) {
      return r.isEmpty || r.every((e) => e == ConnectivityResult.none);
    }
    return r == ConnectivityResult.none;
  }

  Future<void> _checkConnectivity() async {
    final r = await Connectivity().checkConnectivity();
    if (mounted) setState(() => _isOffline = _parseOffline(r));
  }

  Future<void> _setError() async {
    final r = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _hasError = true;
        _isOffline = _parseOffline(r);
      });
    }
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _loaded = false;
      _progress = 0;
    });
    _wvc?.reload();
  }

  void _loadUrl(String url) {
    setState(() {
      _loaded = false;
      _hasError = false;
      _progress = 0;
      _canGoBack = false;
    });
    _wvc?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  // Browser back (WebView history)
  Future<bool> _browserGoBack() async {
    if (_wvc != null && await _wvc!.canGoBack()) {
      _wvc!.goBack();
      return true; // consumed
    }
    return false; // not consumed — let cubit handle it
  }

  // ── Disclaimer ─────────────────────────────────────────────────────────────

  void _maybeDisclaimer() {
    final shown = MyHiveBoxes.user
        .get(MyHiveKeys.onlineMusicDialogShown, defaultValue: false) as bool;
    if (shown) return;
    MyHiveBoxes.user.put(MyHiveKeys.onlineMusicDialogShown, true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _DisclaimerDialog(primary: Theme.of(context).colorScheme.primary),
    );
  }

  // ── Category accent ────────────────────────────────────────────────────────

  static Color _catColor(int cat) {
    const m = {
      kCategoryMusic: Color(0xFF9C27B0),
      kCategoryMovies: Color(0xFFD32F2F),
      kCategoryLoFi: Color(0xFF00897B),
      kCategoryRoyaltyFree: Color(0xFFF57C00),
      kCategoryDocs: Color(0xFF1565C0),
    };
    return m[cat] ?? const Color(0xFF607D8B);
  }

  // ── Main build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final mq = MediaQuery.of(context);

    return BlocConsumer<OnlineSectionCubit, OnlineSectionState>(
      // React to orientation changes
      listenWhen: (p, c) =>
          p.isLandscapeEnabled != c.isLandscapeEnabled ||
          (p.activeInstance.url != c.activeInstance.url && c.isBrowserMode),
      listener: (_, st) {
        _applyOrientation(st.isLandscapeEnabled);
        if (st.isBrowserMode) _loadUrl(st.activeInstance.url);
      },
      builder: (ctx, st) {
        final cubit = ctx.read<OnlineSectionCubit>();
        final Color accent = _catColor(st.selectedCategory);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (_, __) async {
              // In browser: try WebView history first, then section back
              if (st.isBrowserMode) {
                final consumed = await _browserGoBack();
                if (!consumed) cubit.goBack();
              } else {
                final consumed = cubit.goBack();
                if (!consumed && mounted) Navigator.of(context).maybePop();
              }
            },
            child: Container(
              color: const Color(0xFF060610),
              child: SafeArea(
                bottom: false,
                child: Column(children: [
                  // ── TOP BAR (always 44 px, collapses to 0 in browser) ────
                  _TopBar(
                    st: st,
                    canGoBack: _canGoBack,
                    isLoading: !_loaded && !_hasError && st.isBrowserMode,
                    progress: _progress,
                    accent: accent,
                    onBack: () async {
                      if (st.isBrowserMode) {
                        final consumed = await _browserGoBack();
                        if (!consumed) cubit.goBack();
                      } else {
                        cubit.goBack();
                      }
                    },
                    onNavBarToggle: cubit.toggleNavBar,
                    onAdBlockToggle: cubit.toggleAdBlock,
                    onBgPlayToggle: cubit.toggleBackgroundPlay,
                    onLandscapeToggle: cubit.toggleLandscape,
                    onTopBarToggle: cubit.toggleTopBar,
                    onReload: _retry,
                  ),

                  // ── INSTANCE CHIPS (36 px, browser only) ─────────────────
                  if (st.isBrowserMode && st.isTopBarVisible)
                    _InstanceChips(
                      st: st,
                      accent: accent,
                      onTap: (inst) {
                        cubit.openInstance(inst);
                      },
                      onAdd: () => _showAdd(ctx, accent),
                      onDelete: cubit.deleteCustomInstance,
                    ),

                  // ── CONTENT ───────────────────────────────────────────────
                  Expanded(
                    child: _buildContent(ctx, st, cubit, accent, mq),
                  ),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext ctx, OnlineSectionState st,
      OnlineSectionCubit cubit, Color accent, MediaQueryData mq) {
    switch (st.navLevel) {
      case kNavExplore:
        return _ExploreGrid(
          st: st,
          mq: mq,
          onCategory: cubit.openCategory,
          onAdd: () => _showAdd(ctx, accent),
        );
      case kNavSites:
        return _SitesList(
          st: st,
          accent: accent,
          onInstance: cubit.openInstance,
          onAdd: () => _showAdd(ctx, accent),
          onDelete: cubit.deleteCustomInstance,
        );
      default: // kNavBrowser
        return _Browser(
          st: st,
          settings: _wvSettings,
          keepAlive: _keepAlive,
          adDomains: _adDomains,
          adJS: _adJS,
          loaded: _loaded,
          hasError: _hasError,
          isOffline: _isOffline,
          progress: _progress,
          accent: accent,
          isTopBarVisible: st.isTopBarVisible,
          onCreated: (c) => _wvc = c,
          onLoadStart: () => setState(() {
            _loaded = false;
            _hasError = false;
          }),
          onLoadStop: (c) async {
            if (st.isAdBlockEnabled) {
              await c.evaluateJavascript(source: _adJS);
            }
            final b = await c.canGoBack();
            if (mounted) {
              setState(() {
                _loaded = true;
                _canGoBack = b;
              });
            }
          },
          onProgress: (p) {
            if (mounted) setState(() => _progress = p / 100);
          },
          onHistoryUpdate: (b) {
            if (mounted) setState(() => _canGoBack = b);
          },
          onError: _setError,
          onRetry: _retry,
          onRevealTopBar: () => ctx.read<OnlineSectionCubit>().showTopBar(), onAdd: () {  },
        );
    }
  }

  void _showAdd(BuildContext ctx, Color accent) {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    String? err;
    showDialog(
      context: ctx,
      builder: (dCtx) => StatefulBuilder(
          builder: (_, ss) => Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10101C),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accent.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accent.withValues(alpha: 0.12)),
                              child: Icon(Icons.add_link_rounded,
                                  color: accent, size: 17)),
                          const Gap(12),
                          Text('Add Custom Site',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: AppFonts.poppins)),
                        ]),
                        const Gap(18),
                        _TF(
                            ctrl: urlCtrl,
                            label: 'URL *',
                            hint: 'https://example.com',
                            icon: Icons.link_rounded,
                            accent: accent,
                            type: TextInputType.url),
                        const Gap(10),
                        _TF(
                            ctrl: nameCtrl,
                            label: 'Name (optional)',
                            hint: 'My Site',
                            icon: Icons.label_outline_rounded,
                            accent: accent),
                        if (err != null)
                          Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(err!,
                                  style: const TextStyle(
                                      color: Colors.redAccent, fontSize: 11))),
                        const Gap(18),
                        Row(children: [
                          Expanded(
                              child: _Btn(
                                  label: 'Cancel',
                                  bg: Colors.white10,
                                  fg: Colors.white38,
                                  onTap: () => Navigator.pop(dCtx))),
                          const Gap(10),
                          Expanded(
                              child: _Btn(
                            label: 'Add',
                            bg: accent.withValues(alpha: 0.15),
                            fg: accent,
                            border: accent.withValues(alpha: 0.4),
                            onTap: () {
                              final url = urlCtrl.text.trim();
                              if (url.isEmpty) {
                                ss(() => err = 'URL is required');
                                return;
                              }
                              final ok = ctx
                                  .read<OnlineSectionCubit>()
                                  .addCustomInstance(
                                      name: nameCtrl.text, url: url);
                              if (!ok) {
                                ss(() => err = 'URL already exists');
                                return;
                              }
                              Navigator.pop(dCtx);
                            },
                          )),
                        ]),
                      ]),
                ),
              )),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TOP BAR — 44 px, collapsible in browser mode
//
// Explore / Sites:  [←]  [title]              [🛡][👁]
// Browser visible:  [←]  [Cat › Site]         [🛡][🎵][🔄][🌐][⇅][↺]
// Browser hidden:   ────────── 4 dp drag handle ──────────
// ═══════════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.st,
    required this.canGoBack,
    required this.isLoading,
    required this.progress,
    required this.accent,
    required this.onBack,
    required this.onNavBarToggle,
    required this.onAdBlockToggle,
    required this.onBgPlayToggle,
    required this.onLandscapeToggle,
    required this.onTopBarToggle,
    required this.onReload,
  });

  final OnlineSectionState st;
  final bool canGoBack, isLoading;
  final double progress;
  final Color accent;
  final VoidCallback onBack,
      onNavBarToggle,
      onAdBlockToggle,
      onBgPlayToggle,
      onLandscapeToggle,
      onTopBarToggle,
      onReload;

  static const _catLabel = [
    '',
    'Music',
    'Movies',
    'Lo-Fi',
    'Free',
    'Docs',
    'Custom'
  ];

  String get _catName => st.selectedCategory < _catLabel.length
      ? _catLabel[st.selectedCategory]
      : 'Custom';

  @override
  Widget build(BuildContext context) {
    // In browser mode, the top bar is collapsible
    if (st.isBrowserMode && !st.isTopBarVisible) {
      // Show only a tiny drag handle
      return GestureDetector(
        onTap: onTopBarToggle,
        onVerticalDragEnd: (d) {
          if (d.primaryVelocity != null && d.primaryVelocity! > 0) {
            onTopBarToggle();
          }
        },
        child: Container(
          height: 8,
          color: const Color(0xFF09091A),
          child: Center(
            child: Container(
                width: 36,
                height: 3,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2))),
          ),
        ),
      );
    }

    return Column(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
        // Swipe up to collapse (browser only)
        onVerticalDragEnd: st.isBrowserMode
            ? (d) {
                if ((d.primaryVelocity ?? 0) < -200) onTopBarToggle();
              }
            : null,
        child: Container(
          height: 44,
          color: const Color(0xFF09091A),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(children: [
            // ── Back / nav ─────────────────────────────────────────────
            _IBtn(
              icon: Icons.arrow_back_ios_rounded,
              color: (st.isBrowserMode ? canGoBack : !st.isExploreMode)
                  ? Colors.white70
                  : Colors.white24,
              size: 16,
              onTap: (!st.isExploreMode || (st.isBrowserMode && canGoBack))
                  ? onBack
                  : null,
            ),

            // ── Title / breadcrumb ──────────────────────────────────────
            Expanded(
              child: st.isBrowserMode
                  ? GestureDetector(
                      onTap: () {},
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(_catName,
                            style: TextStyle(
                                color: accent.withValues(alpha: 0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                        const Text(' › ',
                            style:
                                TextStyle(color: Colors.white24, fontSize: 11)),
                        Flexible(
                            child: Text(st.activeInstance.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500))),
                      ]),
                    )
                  : Row(children: [
                      const Gap(4),
                      Icon(Icons.language_rounded,
                          color: accent.withValues(alpha: 0.6), size: 13),
                      const Gap(5),
                      Text(st.isSitesMode ? _catName : 'OpenPlayer Web',
                          style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontFamily: AppFonts.poppins)),
                    ]),
            ),

            // ── Action buttons ──────────────────────────────────────────
            // Ad block (always visible)
            _IBtn(
              icon: st.isAdBlockEnabled
                  ? Icons.security_rounded
                  : Icons.security_outlined,
              color: st.isAdBlockEnabled
                  ? const Color(0xFF69F0AE)
                  : Colors.white24,
              size: 16,
              tooltip: st.isAdBlockEnabled ? 'Ad Block ON' : 'Ad Block OFF',
              onTap: onAdBlockToggle,
            ),

            // Nav bar hide (always visible)
            _IBtn(
              icon: st.navBarHidden
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: st.navBarHidden ? accent : Colors.white30,
              size: 16,
              onTap: onNavBarToggle,
            ),

            // Browser-only controls
            if (st.isBrowserMode) ...[
              // Background play
              _IBtn(
                icon: st.isBackgroundPlayEnabled
                    ? Icons.headphones_rounded
                    : Icons.headphones_outlined,
                color: st.isBackgroundPlayEnabled
                    ? const Color(0xFFFFD54F)
                    : Colors.white24,
                size: 16,
                tooltip: 'Background Play',
                onTap: onBgPlayToggle,
              ),

              // Landscape rotation
              _IBtn(
                icon: st.isLandscapeEnabled
                    ? Icons.screen_rotation_rounded
                    : Icons.screen_lock_portrait_rounded,
                color: st.isLandscapeEnabled ? accent : Colors.white30,
                size: 16,
                tooltip: 'Rotate',
                onTap: onLandscapeToggle,
              ),

              // Reload
              _IBtn(
                  icon: Icons.refresh_rounded,
                  color: Colors.white30,
                  size: 16,
                  onTap: onReload),

              // Collapse bar (small down arrow)
              _IBtn(
                  icon: Icons.keyboard_arrow_up_rounded,
                  color: Colors.white24,
                  size: 16,
                  onTap: onTopBarToggle),
            ],
          ]),
        ),
      ),
      if (isLoading)
        LinearProgressIndicator(
          value: progress > 0 ? progress : null,
          backgroundColor: Colors.white10,
          valueColor: AlwaysStoppedAnimation<Color>(accent),
          minHeight: 2,
        ),
    ]);
  }
}

class _IBtn extends StatelessWidget {
  const _IBtn(
      {required this.icon,
      required this.color,
      required this.size,
      required this.onTap,
      this.tooltip});
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback? onTap;
  final String? tooltip;
  @override
  Widget build(BuildContext context) {
    final btn = IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: size),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// INSTANCE CHIPS — 36 px horizontal scroll (browser mode)
// ═══════════════════════════════════════════════════════════════════════════════

class _InstanceChips extends StatelessWidget {
  const _InstanceChips(
      {required this.st,
      required this.accent,
      required this.onTap,
      required this.onAdd,
      required this.onDelete});
  final OnlineSectionState st;
  final Color accent;
  final ValueChanged<OnlineInstance> onTap;
  final VoidCallback onAdd;
  final ValueChanged<OnlineInstance> onDelete;

  @override
  Widget build(BuildContext context) {
    final instances = st.currentInstances;
    return Container(
      color: const Color(0xFF09091A),
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
        children: [
          ...instances.map((inst) {
            final active = st.activeInstance.url == inst.url;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap(inst);
                },
                onLongPress:
                    inst.isCustom ? () => _deleteSheet(context, inst) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: active
                        ? accent.withValues(alpha: 0.14)
                        : Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                        color: active
                            ? accent.withValues(alpha: 0.55)
                            : Colors.white12,
                        width: active ? 1.5 : 1),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(inst.name,
                        style: TextStyle(
                            color: active ? accent : Colors.white54,
                            fontSize: 11,
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w400)),
                    if (inst.isCustom) ...[
                      const Gap(3),
                      Icon(Icons.close_rounded,
                          size: 9,
                          color: active
                              ? accent.withValues(alpha: 0.5)
                              : Colors.white24)
                    ],
                  ]),
                ),
              ),
            );
          }),
          if (st.selectedCategory == kCategoryCustom)
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: accent.withValues(alpha: 0.06),
                    border: Border.all(color: accent.withValues(alpha: 0.3))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_rounded,
                      size: 11, color: accent.withValues(alpha: 0.7)),
                  const Gap(3),
                  Text('Add',
                      style: TextStyle(
                          color: accent.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  void _deleteSheet(BuildContext ctx, OnlineInstance inst) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        decoration: const BoxDecoration(
            color: Color(0xFF10101C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: Colors.white10))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2))),
          Text(inst.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const Gap(3),
          Text(inst.url,
              style: const TextStyle(color: Colors.white38, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const Gap(16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withValues(alpha: 0.1)),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Colors.red, size: 16)),
            title: const Text('Remove',
                style: TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(ctx);
              onDelete(inst);
            },
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXPLORE GRID — 6 category cards
// ═══════════════════════════════════════════════════════════════════════════════

class _ExploreGrid extends StatelessWidget {
  const _ExploreGrid(
      {required this.st,
      required this.mq,
      required this.onCategory,
      required this.onAdd});
  final OnlineSectionState st;
  final MediaQueryData mq;
  final ValueChanged<int> onCategory;
  final VoidCallback onAdd;

  static const _defs = [
    _CatDef(
        kCategoryMusic,
        '🎵',
        'Music',
        'Stream & discover',
        'Hayasaka · ArtistGrid · MusicPlayer',
        3,
        [Color(0xFF4A148C), Color(0xFF7B1FA2), Color(0xFF1A0030)]),
    _CatDef(
        kCategoryMovies,
        '🎬',
        'Movies & TV',
        'Watch anything',
        'Cineby · Rivestream · Fmovies · +6',
        9,
        [Color(0xFF7F0000), Color(0xFFB71C1C), Color(0xFF1C0000)]),
    _CatDef(
        kCategoryLoFi,
        '🌙',
        'Lo-Fi Radio',
        'Chill & focus',
        'Lofi.limo · Loficafe · FlowFi · +9',
        12,
        [Color(0xFF004D40), Color(0xFF00695C), Color(0xFF001510)]),
    _CatDef(
        kCategoryRoyaltyFree,
        '🎸',
        'Royalty Free',
        'Music for creators',
        'NCS · Bensound · Unminus · TuneTank',
        4,
        [Color(0xFFBF360C), Color(0xFFE64A19), Color(0xFF3E0E00)]),
    _CatDef(
        kCategoryDocs,
        '📽️',
        'Documentaries',
        'Knowledge & stories',
        'NASA+ · ARTE · Thoughtmaybe · +5',
        8,
        [Color(0xFF0D1B5E), Color(0xFF1A237E), Color(0xFF050A28)]),
    _CatDef(
        kCategoryCustom,
        '⚙️',
        'Custom',
        'Your own sites',
        'Add any URL to browse here',
        -1,
        [Color(0xFF1C2126), Color(0xFF263238), Color(0xFF0A0D0F)]),
  ];

  @override
  Widget build(BuildContext context) {
    final cols = mq.size.width >= 600 ? 3 : 2;
    final pad = mq.size.width >= 600 ? 16.0 : 12.0;
    return Container(
      color: const Color(0xFF060610),
      child: CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
        SliverToBoxAdapter(
            child: Padding(
          padding: EdgeInsets.fromLTRB(pad, 18, pad, 14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            RichText(
                text: TextSpan(children: [
              TextSpan(
                  text: 'Open',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      fontFamily: AppFonts.poppins,
                      letterSpacing: -0.5)),
              TextSpan(
                  text: 'Web',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.22),
                      fontSize: 26,
                      fontWeight: FontWeight.w300,
                      fontFamily: AppFonts.poppins,
                      letterSpacing: -0.5)),
            ])),
            const Gap(3),
            Text('40+ curated sites across 6 categories',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 11.5)),
          ]),
        )),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(pad, 0, pad, mq.size.height * 0.15),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate((_, i) {
              final d = _defs[i];
              final cnt =
                  d.id == kCategoryCustom ? st.customInstances.length : d.count;
              return _CatCard(
                  def: d,
                  count: cnt,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    if (d.id == kCategoryCustom && cnt == 0) {
                      onAdd();
                    } else {
                      onCategory(d.id);
                    }
                  });
            }, childCount: _defs.length),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: mq.size.width >= 600 ? 0.88 : 0.80,
            ),
          ),
        ),
      ]),
    );
  }
}

class _CatDef {
  final int id;
  final String emoji, name, sub, desc;
  final int count;
  final List<Color> grad;
  const _CatDef(this.id, this.emoji, this.name, this.sub, this.desc, this.count,
      this.grad);
}

class _CatCard extends StatelessWidget {
  const _CatCard({required this.def, required this.count, required this.onTap});
  final _CatDef def;
  final int count;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: def.grad,
                stops: const [0.0, 0.5, 1.0]),
            boxShadow: [
              BoxShadow(
                  color: def.grad[1].withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: -3,
                  offset: const Offset(0, 5))
            ],
          ),
          child: Stack(children: [
            Positioned.fill(
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CustomPaint(painter: _DotPainter(def.grad[1])))),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(def.emoji, style: const TextStyle(fontSize: 28)),
                          if (count > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.black.withValues(alpha: 0.35)),
                              child: Text('$count',
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700)),
                            ),
                        ]),
                    const Spacer(),
                    Text(def.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            fontFamily: AppFonts.poppins,
                            letterSpacing: -0.2)),
                    const Gap(2),
                    Text(def.sub,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10.5,
                            height: 1.3)),
                    const Gap(7),
                    Text(def.desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.28),
                            fontSize: 9.5,
                            height: 1.4)),
                    const Gap(9),
                    Row(children: [
                      Text(
                          def.id == kCategoryCustom && count == 0
                              ? 'Add site'
                              : 'View sites',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      const Gap(3),
                      Icon(Icons.arrow_forward_rounded,
                          size: 11, color: Colors.white.withValues(alpha: 0.6)),
                    ]),
                  ]),
            ),
          ]),
        ),
      );
}

class _DotPainter extends CustomPainter {
  const _DotPainter(this.t);
  final Color t;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.03);
    for (double x = 14; x < size.width; x += 22)
      for (double y = 14; y < size.height; y += 22) {
        canvas.drawCircle(Offset(x, y), 1.2, p);
      }
    canvas.drawCircle(
        Offset.zero,
        90,
        Paint()
          ..shader = RadialGradient(
                  colors: [t.withValues(alpha: 0.12), Colors.transparent])
              .createShader(Rect.fromCircle(center: Offset.zero, radius: 90)));
  }

  @override
  bool shouldRepaint(_DotPainter o) => o.t != t;
}

// ═══════════════════════════════════════════════════════════════════════════════
// SITES LIST — scrollable list of all sites in a category (level 1)
// ═══════════════════════════════════════════════════════════════════════════════

class _SitesList extends StatelessWidget {
  const _SitesList(
      {required this.st,
      required this.accent,
      required this.onInstance,
      required this.onAdd,
      required this.onDelete});
  final OnlineSectionState st;
  final Color accent;
  final ValueChanged<OnlineInstance> onInstance;
  final VoidCallback onAdd;
  final ValueChanged<OnlineInstance> onDelete;

  static const _catLabel = [
    '',
    'Music',
    'Movies & TV',
    'Lo-Fi Radio',
    'Royalty Free',
    'Documentaries',
    'Custom'
  ];
  static const _catDesc = [
    '',
    'Stream music from these sites',
    'Movies & TV from these streaming services',
    'Chill beats & ambient radio',
    'Royalty-free music for creators',
    'Documentaries & educational content',
    'Your custom sites',
  ];

  @override
  Widget build(BuildContext context) {
    final instances = st.currentInstances;
    final name = st.selectedCategory < _catLabel.length
        ? _catLabel[st.selectedCategory]
        : 'Sites';
    final desc = st.selectedCategory < _catDesc.length
        ? _catDesc[st.selectedCategory]
        : '';
    final mq = MediaQuery.sizeOf(context);

    return Container(
      color: const Color(0xFF060610),
      child: CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
        // Header
        SliverToBoxAdapter(
            child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: TextStyle(
                    color: accent,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    fontFamily: AppFonts.poppins)),
            const Gap(3),
            Text(desc,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35), fontSize: 12)),
          ]),
        )),

        // Site cards
        if (instances.isEmpty)
          SliverToBoxAdapter(child: _EmptyCustom(accent: accent, onAdd: onAdd))
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, mq.height * 0.14),
            sliver: SliverList(
                delegate: SliverChildBuilderDelegate((_, i) {
              final inst = instances[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SiteCard(
                  inst: inst,
                  accent: accent,
                  index: i,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onInstance(inst);
                  },
                  onDelete: inst.isCustom ? () => onDelete(inst) : null,
                ),
              );
            }, childCount: instances.length)),
          ),

        // Add button for Custom tab
        if (st.selectedCategory == kCategoryCustom)
          SliverToBoxAdapter(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            child: GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: accent.withValues(alpha: 0.07),
                  border: Border.all(
                      color: accent.withValues(alpha: 0.25), width: 1.5),
                ),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.add_rounded,
                      color: accent.withValues(alpha: 0.7), size: 18),
                  const Gap(8),
                  Text('Add New Site',
                      style: TextStyle(
                          color: accent.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          )),
      ]),
    );
  }
}

class _SiteCard extends StatelessWidget {
  const _SiteCard(
      {required this.inst,
      required this.accent,
      required this.index,
      required this.onTap,
      this.onDelete});
  final OnlineInstance inst;
  final Color accent;
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(children: [
          // Numbered circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.12),
                border: Border.all(color: accent.withValues(alpha: 0.2))),
            child: Center(
                child: Text('${index + 1}',
                    style: TextStyle(
                        color: accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w700))),
          ),
          const Gap(14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(inst.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const Gap(2),
                Text(inst.description.isNotEmpty ? inst.description : inst.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11)),
              ])),
          const Gap(8),
          if (onDelete != null)
            GestureDetector(
              onTap: onDelete,
              child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline_rounded,
                      size: 16, color: Colors.red.withValues(alpha: 0.6))),
            )
          else
            Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: accent.withValues(alpha: 0.5)),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BROWSER — WebView wrapper (level 2)
// ═══════════════════════════════════════════════════════════════════════════════

class _Browser extends StatelessWidget {
  const _Browser({
    required this.st,
    required this.settings,
    required this.keepAlive,
    required this.adDomains,
    required this.adJS,
    required this.loaded,
    required this.hasError,
    required this.isOffline,
    required this.progress,
    required this.accent,
    required this.isTopBarVisible,
    required this.onCreated,
    required this.onLoadStart,
    required this.onLoadStop,
    required this.onProgress,
    required this.onHistoryUpdate,
    required this.onError,
    required this.onRetry,
    required this.onAdd,
    required this.onRevealTopBar,
  });
  final OnlineSectionState st;
  final InAppWebViewSettings settings;
  final InAppWebViewKeepAlive keepAlive;
  final Set<String> adDomains;
  final String adJS;
  final bool loaded, hasError, isOffline, isTopBarVisible;
  final double progress;
  final Color accent;
  final ValueChanged<InAppWebViewController> onCreated;
  final VoidCallback onLoadStart, onError, onRetry, onAdd, onRevealTopBar;
  final ValueChanged<InAppWebViewController> onLoadStop;
  final ValueChanged<double> onProgress;
  final ValueChanged<bool> onHistoryUpdate;

  @override
  Widget build(BuildContext context) {
    if (st.selectedCategory == kCategoryCustom && st.customInstances.isEmpty) {
      return _EmptyCustom(accent: accent, onAdd: onAdd);
    }

    return Stack(children: [
      // Top drag handle to reveal collapsed bar (only when bar is hidden)
      if (!isTopBarVisible)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: GestureDetector(
            onVerticalDragEnd: (d) {
              if ((d.primaryVelocity ?? 0) > 80) onRevealTopBar();
            },
            onTap: onRevealTopBar,
            child: Container(
                height: 20,
                color: Colors.transparent,
                child: Center(
                    child: Container(
                        width: 36,
                        height: 3,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2))))),
          ),
        ),

      Opacity(
        opacity: hasError ? 0.0 : 1.0,
        child: InAppWebView(
          keepAlive: keepAlive,
          initialUrlRequest: URLRequest(url: WebUri(st.activeInstance.url)),
          initialSettings: settings,
          onWebViewCreated: onCreated,
          onLoadStart: (_, __) => onLoadStart(),
          onLoadStop: (c, _) => onLoadStop(c),
          onProgressChanged: (_, p) => onProgress(p.toDouble()),
          onUpdateVisitedHistory: (c, _, __) async =>
              onHistoryUpdate(await c.canGoBack()),
          onReceivedError: (_, req, __) {
            if (req.isForMainFrame ?? false) onError();
          },
          onReceivedHttpError: (_, req, res) {
            if ((req.isForMainFrame ?? false) && (res.statusCode ?? 0) >= 400) {
              onError();
            }
          },
          shouldOverrideUrlLoading: (_, action) async {
            final url = action.request.url?.toString() ?? '';
            final host = Uri.tryParse(url)?.host ?? '';
            // Block ad domains at URL level
            if (adDomains.any((d) => host.contains(d))) {
              return NavigationActionPolicy.CANCEL;
            }
            // Allow all http/https and special schemes
            if (url.startsWith('http') ||
                url.startsWith('about:') ||
                url.startsWith('blob:') ||
                url.startsWith('data:') ||
                url.startsWith('javascript:')) {
              return NavigationActionPolicy.ALLOW;
            }
            return NavigationActionPolicy.CANCEL;
          },
        ),
      ),

      if (!loaded && !hasError)
        _Loader(
            progress: progress, accent: accent, name: st.activeInstance.name),
      if (hasError) _Err(offline: isOffline, accent: accent, onRetry: onRetry),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED SMALL WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _Loader extends StatelessWidget {
  const _Loader(
      {required this.progress, required this.accent, required this.name});
  final double progress;
  final Color accent;
  final String name;
  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFF060610),
        child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
              width: 52,
              height: 52,
              child: CircularProgressIndicator(
                  value: progress > 0 ? progress : null,
                  color: accent,
                  backgroundColor: accent.withValues(alpha: 0.1),
                  strokeWidth: 2.5)),
          const Gap(16),
          Text(name,
              style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppFonts.poppins)),
          const Gap(5),
          Text('${(progress * 100).toInt()}%',
              style: TextStyle(
                  color: accent.withValues(alpha: 0.7),
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
        ])),
      );
}

class _Err extends StatelessWidget {
  const _Err(
      {required this.offline, required this.accent, required this.onRetry});
  final bool offline;
  final Color accent;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFF060610),
        child: Center(
            child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(offline ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
                size: 52, color: Colors.white12),
            const Gap(16),
            Text(offline ? 'No Internet' : 'Failed to Load',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const Gap(8),
            Text(
                offline
                    ? 'Check your connection.'
                    : 'Try switching to another instance.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 12, height: 1.5)),
            const Gap(20),
            SizedBox(
                width: 130,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10)),
                )),
          ]),
        )),
      );
}

class _EmptyCustom extends StatelessWidget {
  const _EmptyCustom({required this.accent, required this.onAdd});
  final Color accent;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFF060610),
        child: Center(
            child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.07),
                    border: Border.all(
                        color: accent.withValues(alpha: 0.15), width: 1.5)),
                child: Icon(Icons.add_link_rounded,
                    color: accent.withValues(alpha: 0.45), size: 26)),
            const Gap(16),
            const Text('No Custom Sites',
                style: TextStyle(
                    color: Colors.white60,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const Gap(8),
            const Text('Add any website URL to browse it here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white24, fontSize: 12, height: 1.5)),
            const Gap(18),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add a Site',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
            ),
          ]),
        )),
      );
}

class _DisclaimerDialog extends StatelessWidget {
  const _DisclaimerDialog({required this.primary});
  final Color primary;
  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
              color: const Color(0xFF0E0E1C),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: primary.withValues(alpha: 0.2))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary.withValues(alpha: 0.12)),
                child: Icon(Icons.language_rounded, color: primary, size: 22)),
            const Gap(14),
            const Text('OpenPlayer Web',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    fontFamily: AppFonts.poppins)),
            const Gap(12),
            const Text(
                '🛡️  Advanced ad blocker (ON by default)\n'
                '🌙  Browse music · movies · lo-fi · docs\n'
                '🎸  Royalty-free music for creators\n'
                '⚙️  Add your own custom URLs\n'
                '👁️  Collapse top bar for full screen\n'
                '🎵  Background play toggle\n'
                '🔄  Landscape unlock for videos',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white54, fontSize: 12, height: 1.8)),
            const Gap(18),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0),
                  child: const Text("Let's explore!",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                )),
          ]),
        ),
      );
}

class _TF extends StatelessWidget {
  const _TF(
      {required this.ctrl,
      required this.label,
      required this.hint,
      required this.icon,
      required this.accent,
      this.type});
  final TextEditingController ctrl;
  final String label, hint;
  final IconData icon;
  final Color accent;
  final TextInputType? type;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 10,
                fontWeight: FontWeight.w600)),
        const Gap(5),
        TextField(
          controller: ctrl,
          keyboardType: type,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
            prefixIcon: Icon(icon, color: Colors.white24, size: 15),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white12)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white12)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: accent.withValues(alpha: 0.55))),
          ),
        ),
      ]);
}

class _Btn extends StatelessWidget {
  const _Btn(
      {required this.label,
      required this.bg,
      required this.fg,
      required this.onTap,
      this.border});
  final String label;
  final Color bg, fg;
  final Color? border;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: bg,
              border: border != null
                  ? Border.all(color: border!, width: 1.5)
                  : null),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: fg, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      );
}
