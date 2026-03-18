import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'bottom_nav_bar_state.dart';

class BottomNavBarCubit extends Cubit<BottomNavBarState> {
  BottomNavBarCubit() : super( const BottomNavBarState(index: 0));

  changeIndex({required int index}) {
    emit(state.copyWith(index));
  }
}
