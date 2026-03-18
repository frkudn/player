import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:open_player/presentation/shared/widgets/custom_filter_chip.dart';
import 'package:velocity_x/velocity_x.dart';

enum SongsFiltered { all, favorites, recents, hidden }

// Extension to provide custom display names
extension SongsFilterExtension on SongsFiltered {
  String get displayName {
    switch (this) {
      case SongsFiltered.all:
        return 'All';
      case SongsFiltered.recents:
        return 'Recently Added';
      case SongsFiltered.favorites:
        return 'Favorites';
      case SongsFiltered.hidden:
        return 'Hidden';
    }
  }
}

class SongsTopBarButtonsWidget extends HookWidget {
  const SongsTopBarButtonsWidget(
      {super.key, required this.songsLength, required this.selectedFilter});

  final int songsLength;

  final ValueNotifier<SongsFiltered> selectedFilter;

  @override
  Widget build(BuildContext context) {
    return SlideInDown(
      child: SizedBox(
        height: 60,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
          child: Row(
            children: [
              //----- Sorting Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: Row(
                  children: SongsFiltered.values.map((filter) {
                    final isSelected =  selectedFilter.value == filter;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Stack(
                        children: [
                          CustomFilterChip(
                            isSelected: isSelected,
                            label: filter.displayName.toUpperCase(),
                            sideWidget: isSelected
                                ? songsLength.text.white.xs.make().pSymmetric(h: 4).glassMorphic().pOnly(left: 4)
                                : null,
                            onSelected: () {
                              selectedFilter.value = filter;
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ).scrollHorizontal(),
              ),
            ],
          ).scrollHorizontal(),
        ),
      ),
    );
  }
}
