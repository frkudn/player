import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:open_player/base/db/hive_service.dart';
import 'package:open_player/presentation/features/online_section/models/online_instance.dart';
import '../data/online_data_instances.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NAVIGATION LEVELS
//   0 = Explore   — category grid home
//   1 = Sites     — scrollable site list for the selected category
//   2 = Browser   — full WebView for the selected instance
// ─────────────────────────────────────────────────────────────────────────────

const int kNavExplore = 0;
const int kNavSites = 1;
const int kNavBrowser = 2;

// ─────────────────────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────────────────────

class OnlineSectionState extends Equatable {
  // ── Navigation ─────────────────────────────────────────────────────────────
  final int navLevel; // 0/1/2 — see constants above
  final int selectedCategory; // which category tab is open

  // ── Active site ────────────────────────────────────────────────────────────
  final OnlineInstance activeInstance;

  // ── Custom instances ───────────────────────────────────────────────────────
  final List<OnlineInstance> customInstances;

  // ── UI toggles ─────────────────────────────────────────────────────────────
  /// Hides the app's bottom nav bar when in WebView
  final bool navBarHidden;

  /// JS + URL-level ad/popup blocker; default ON
  final bool isAdBlockEnabled;

  /// Allows media to keep playing when the app is minimised/screen locked.
  /// Uses WebView's keepAlive + wakelock. Default OFF (privacy-friendly).
  final bool isBackgroundPlayEnabled;

  /// When true the orientation is unlocked so videos can go landscape.
  /// The page toggles SystemChrome on every state change.
  final bool isLandscapeEnabled;

  /// Whether the compact top bar inside the WebView is visible.
  /// User can tap a thin reveal handle to show it again.
  final bool isTopBarVisible;

  const OnlineSectionState({
    required this.navLevel,
    required this.selectedCategory,
    required this.activeInstance,
    required this.customInstances,
    required this.navBarHidden,
    required this.isAdBlockEnabled,
    required this.isBackgroundPlayEnabled,
    required this.isLandscapeEnabled,
    required this.isTopBarVisible,
  });

  factory OnlineSectionState.initial() => OnlineSectionState(
        navLevel: kNavExplore,
        selectedCategory: kCategoryExplore,
        activeInstance: kMusicInstances.first,
        customInstances: const [],
        navBarHidden: false,
        isAdBlockEnabled: true,
        isBackgroundPlayEnabled: false,
        isLandscapeEnabled: false,
        isTopBarVisible: true,
      );

  OnlineSectionState copyWith({
    int? navLevel,
    int? selectedCategory,
    OnlineInstance? activeInstance,
    List<OnlineInstance>? customInstances,
    bool? navBarHidden,
    bool? isAdBlockEnabled,
    bool? isBackgroundPlayEnabled,
    bool? isLandscapeEnabled,
    bool? isTopBarVisible,
  }) =>
      OnlineSectionState(
        navLevel: navLevel ?? this.navLevel,
        selectedCategory: selectedCategory ?? this.selectedCategory,
        activeInstance: activeInstance ?? this.activeInstance,
        customInstances: customInstances ?? this.customInstances,
        navBarHidden: navBarHidden ?? this.navBarHidden,
        isAdBlockEnabled: isAdBlockEnabled ?? this.isAdBlockEnabled,
        isBackgroundPlayEnabled:
            isBackgroundPlayEnabled ?? this.isBackgroundPlayEnabled,
        isLandscapeEnabled: isLandscapeEnabled ?? this.isLandscapeEnabled,
        isTopBarVisible: isTopBarVisible ?? this.isTopBarVisible,
      );

  /// Shorthand getters
  bool get isExploreMode => navLevel == kNavExplore;
  bool get isSitesMode => navLevel == kNavSites;
  bool get isBrowserMode => navLevel == kNavBrowser;

  List<OnlineInstance> get currentInstances =>
      OnlineSectionState.instancesFor(selectedCategory, customInstances);

  static List<OnlineInstance> instancesFor(
      int category, List<OnlineInstance> custom) {
    switch (category) {
      case kCategoryMusic:
        return kMusicInstances;
      case kCategoryMovies:
        return kMovieInstances;
      case kCategoryLoFi:
        return kLoFiInstances;
      case kCategoryRoyaltyFree:
        return kRoyaltyFreeInstances;
      case kCategoryDocs:
        return kDocInstances;
      case kCategoryCustom:
        return custom;
      default:
        return const [];
    }
  }

  @override
  List<Object?> get props => [
        navLevel,
        selectedCategory,
        activeInstance,
        customInstances,
        navBarHidden,
        isAdBlockEnabled,
        isBackgroundPlayEnabled,
        isLandscapeEnabled,
        isTopBarVisible,
      ];
}

// ─────────────────────────────────────────────────────────────────────────────
// CUBIT
// ─────────────────────────────────────────────────────────────────────────────

class OnlineSectionCubit extends Cubit<OnlineSectionState> {
  OnlineSectionCubit() : super(OnlineSectionState.initial()) {
    _loadCustomInstances();
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  void _loadCustomInstances() {
    try {
      final raw =
          MyHiveBoxes.user.get(MyHiveKeys.onlineCustomInstances) as String?;
      if (raw == null || raw.isEmpty) return;
      final list = (jsonDecode(raw) as List)
          .map((e) => OnlineInstance.fromJson(e as Map<String, dynamic>))
          .toList();
      emit(state.copyWith(customInstances: list));
    } catch (_) {}
  }

  void _saveCustomInstances(List<OnlineInstance> list) {
    MyHiveBoxes.user.put(
      MyHiveKeys.onlineCustomInstances,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  /// Go to the explore grid (level 0).
  void goToExplore() {
    emit(state.copyWith(
      navLevel: kNavExplore,
      selectedCategory: kCategoryExplore,
      isLandscapeEnabled: false, // always portrait on explore
      isTopBarVisible: true,
    ));
  }

  /// Open a category → show its site list (level 1).
  void openCategory(int category) {
    final instances =
        OnlineSectionState.instancesFor(category, state.customInstances);
    emit(state.copyWith(
      navLevel: kNavSites,
      selectedCategory: category,
      isTopBarVisible: true,
    ));
    // If there are no instances (empty Custom), stay on sites screen
    // so user sees the "Add site" CTA instead of blank WebView.
  }

  /// Open a specific site in the WebView (level 2).
  void openInstance(OnlineInstance instance) {
    emit(state.copyWith(
      navLevel: kNavBrowser,
      activeInstance: instance,
      isTopBarVisible: true,
    ));
  }

  /// Smart back:
  ///   Browser  → Sites list (does NOT go back in WebView history — the page handles that)
  ///   Sites    → Explore
  ///   Explore  → (noop — let the system handle it)
  /// Returns true if consumed so the page knows whether to call Navigator.pop.
  bool goBack() {
    switch (state.navLevel) {
      case kNavBrowser:
        emit(state.copyWith(
          navLevel: kNavSites,
          isLandscapeEnabled: false,
          isTopBarVisible: true,
        ));
        return true;
      case kNavSites:
        emit(state.copyWith(
          navLevel: kNavExplore,
          selectedCategory: kCategoryExplore,
          isTopBarVisible: true,
        ));
        return true;
      default:
        return false; // let system handle Explore-level back
    }
  }

  // ── Custom instance CRUD ───────────────────────────────────────────────────

  bool addCustomInstance(
      {required String name, required String url, String description = ''}) {
    String clean = url.trim();
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      clean = 'https://$clean';
    }
    if (!clean.endsWith('/')) clean = '$clean/';
    if (state.customInstances.any((i) => i.url == clean)) return false;

    final inst = OnlineInstance(
      name: name.trim().isEmpty ? _domainLabel(clean) : name.trim(),
      url: clean,
      description: description.trim(),
      isCustom: true,
    );
    final updated = [...state.customInstances, inst];
    _saveCustomInstances(updated);
    emit(state.copyWith(customInstances: updated));
    return true;
  }

  void deleteCustomInstance(OnlineInstance inst) {
    final updated = state.customInstances.where((i) => i != inst).toList();
    _saveCustomInstances(updated);
    emit(state.copyWith(
      customInstances: updated,
      // If we deleted the active instance, go back to sites list
      navLevel: state.activeInstance == inst ? kNavSites : state.navLevel,
    ));
  }

  // ── Toggle helpers ─────────────────────────────────────────────────────────

  void toggleNavBar() =>
      emit(state.copyWith(navBarHidden: !state.navBarHidden));
  void showNavBar() {
    if (state.navBarHidden) emit(state.copyWith(navBarHidden: false));
  }

  void toggleAdBlock() =>
      emit(state.copyWith(isAdBlockEnabled: !state.isAdBlockEnabled));
  void toggleBackgroundPlay() => emit(
      state.copyWith(isBackgroundPlayEnabled: !state.isBackgroundPlayEnabled));
  void toggleLandscape() =>
      emit(state.copyWith(isLandscapeEnabled: !state.isLandscapeEnabled));
  void toggleTopBar() =>
      emit(state.copyWith(isTopBarVisible: !state.isTopBarVisible));
  void showTopBar() {
    if (!state.isTopBarVisible) emit(state.copyWith(isTopBarVisible: true));
  }

  // ── Utility ────────────────────────────────────────────────────────────────

  static String _domainLabel(String url) {
    try {
      final host = Uri.parse(url).host.replaceFirst('www.', '');
      final label = host.split('.').first;
      if (label.isNotEmpty) return label[0].toUpperCase() + label.substring(1);
    } catch (_) {}
    return 'Custom';
  }
}
