import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:open_player/base/db/hive_service.dart';
import 'package:open_player/presentation/features/online_section/models/online_instance.dart';

import '../data/online_data_instances.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────────────────────

class OnlineSectionState extends Equatable {
  /// 0=Explore (home), 1=Music, 2=Movies, 3=LoFi, 4=RoyaltyFree, 5=Docs, 6=Custom
  final int selectedCategory;

  /// When true, the explore home grid is shown instead of the WebView.
  /// Tapping a category card sets this to false and loads the first instance.
  final bool isExploreMode;

  /// The site currently loaded in the WebView
  final OnlineInstance activeInstance;

  /// User-added custom instances, persisted in Hive as JSON
  final List<OnlineInstance> customInstances;

  /// When true the app's floating nav bar is hidden for full immersion
  final bool navBarHidden;

  /// When true, JS-level ad removal and URL-level ad domain blocking are active.
  /// Default: true — privacy-first out of the box.
  final bool isAdBlockEnabled;

  const OnlineSectionState({
    required this.selectedCategory,
    required this.isExploreMode,
    required this.activeInstance,
    required this.customInstances,
    required this.navBarHidden,
    required this.isAdBlockEnabled,
  });

  factory OnlineSectionState.initial() => OnlineSectionState(
        selectedCategory: kCategoryExplore,
        isExploreMode: true,
        activeInstance: kMusicInstances.first,
        customInstances: const [],
        navBarHidden: false,
        isAdBlockEnabled: true,
      );

  OnlineSectionState copyWith({
    int? selectedCategory,
    bool? isExploreMode,
    OnlineInstance? activeInstance,
    List<OnlineInstance>? customInstances,
    bool? navBarHidden,
    bool? isAdBlockEnabled,
  }) =>
      OnlineSectionState(
        selectedCategory: selectedCategory ?? this.selectedCategory,
        isExploreMode: isExploreMode ?? this.isExploreMode,
        activeInstance: activeInstance ?? this.activeInstance,
        customInstances: customInstances ?? this.customInstances,
        navBarHidden: navBarHidden ?? this.navBarHidden,
        isAdBlockEnabled: isAdBlockEnabled ?? this.isAdBlockEnabled,
      );

  /// Returns the instance list for the currently selected category
  List<OnlineInstance> get currentInstances => instancesFor(selectedCategory);

  /// Returns instance list for any given category index
  static List<OnlineInstance> instancesFor(int category) {
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
      default:
        return const [];
    }
  }

  @override
  List<Object?> get props => [
        selectedCategory,
        isExploreMode,
        activeInstance,
        customInstances,
        navBarHidden,
        isAdBlockEnabled,
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

  /// Shows the explore home grid without loading a new URL in the WebView.
  void goToExplore() {
    emit(state.copyWith(
      selectedCategory: kCategoryExplore,
      isExploreMode: true,
    ));
  }

  /// Opens a category from the explore grid, loads its first instance.
  void openCategory(int category) {
    final instances = category == kCategoryCustom
        ? state.customInstances
        : OnlineSectionState.instancesFor(category);

    emit(state.copyWith(
      selectedCategory: category,
      isExploreMode: instances.isEmpty ? true : false,
      activeInstance:
          instances.isNotEmpty ? instances.first : state.activeInstance,
    ));
  }

  /// Loads a specific instance in the WebView.
  void selectInstance(OnlineInstance instance) {
    emit(state.copyWith(activeInstance: instance, isExploreMode: false));
  }

  // ── Custom instance management ─────────────────────────────────────────────

  /// Adds a custom instance. Normalizes URL (adds https:// if missing).
  /// Returns false when the URL already exists.
  bool addCustomInstance({
    required String name,
    required String url,
    String description = '',
  }) {
    String clean = url.trim();
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      clean = 'https://$clean';
    }
    if (!clean.endsWith('/')) clean = '$clean/';

    if (state.customInstances.any((i) => i.url == clean)) return false;

    final instance = OnlineInstance(
      name: name.trim().isEmpty ? _domainLabel(clean) : name.trim(),
      url: clean,
      description: description.trim(),
      isCustom: true,
    );

    final updated = [...state.customInstances, instance];
    _saveCustomInstances(updated);

    emit(state.copyWith(
      customInstances: updated,
      selectedCategory: kCategoryCustom,
      isExploreMode: false,
      activeInstance: instance,
    ));
    return true;
  }

  /// Removes a custom instance. Falls back to explore if it was active.
  void deleteCustomInstance(OnlineInstance instance) {
    final updated = state.customInstances.where((i) => i != instance).toList();
    _saveCustomInstances(updated);

    final wasActive = state.activeInstance == instance;
    emit(state.copyWith(
      customInstances: updated,
      selectedCategory: wasActive ? kCategoryExplore : state.selectedCategory,
      isExploreMode: wasActive ? true : state.isExploreMode,
      activeInstance: wasActive ? kMusicInstances.first : state.activeInstance,
    ));
  }

  // ── Toggles ────────────────────────────────────────────────────────────────

  void toggleNavBar() =>
      emit(state.copyWith(navBarHidden: !state.navBarHidden));

  /// Always re-shows the nav bar. Call from dispose() of the page widget.
  void showNavBar() {
    if (state.navBarHidden) emit(state.copyWith(navBarHidden: false));
  }

  void toggleAdBlock() =>
      emit(state.copyWith(isAdBlockEnabled: !state.isAdBlockEnabled));

  // ── Utilities ──────────────────────────────────────────────────────────────

  static String _domainLabel(String url) {
    try {
      final host = Uri.parse(url).host.replaceFirst('www.', '');
      final label = host.split('.').first;
      if (label.isNotEmpty) return label[0].toUpperCase() + label.substring(1);
    } catch (_) {}
    return 'Custom';
  }
}
