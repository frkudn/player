import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:velocity_x/velocity_x.dart';

import '../../../../bloc/greeting/greeting_cubit.dart';

class AppBarGreetingTextWidget extends StatelessWidget {
  const AppBarGreetingTextWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<GreetingCubit, GreetingState, String>(
        selector: (state) => state.greeting,
        builder: (context, state) {
          return state.text
              .minFontSize(20)
              .white
              .shadowColor(Colors.black54)
              .shadowBlur(0.4)
              .fontFamily(AppFonts.arizonia)
              .make();
        });
  }
}
