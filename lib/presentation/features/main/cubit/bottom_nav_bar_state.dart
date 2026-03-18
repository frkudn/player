part of 'bottom_nav_bar_cubit.dart';

class BottomNavBarState extends Equatable {
  const BottomNavBarState({required this.index});

  final int index;

 BottomNavBarState copyWith( index) {
    return BottomNavBarState(index: index ?? this.index);
  }

  @override
  List<Object> get props => [index];
}
