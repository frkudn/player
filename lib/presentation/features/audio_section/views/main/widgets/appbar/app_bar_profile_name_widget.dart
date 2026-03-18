import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:velocity_x/velocity_x.dart';

import '../../../../../settings/user_profile/cubit/user_data/user_data_cubit.dart';
import '../../../../../settings/user_profile/cubit/user_data/user_data_state.dart';

class AppBarProfileNameWidget extends StatelessWidget {
  const AppBarProfileNameWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<UserDataCubit, UserDataState, String>(
      selector: (state) => state.username,
      builder: (context, state) {
        return state.text.minFontSize(12).fontFamily(AppFonts.nabla).make();
      },
    );
  }
}
