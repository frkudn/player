import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/logic/user_data/user_data_cubit.dart';
import 'package:open_player/logic/user_data/user_data_state.dart';
import 'package:velocity_x/velocity_x.dart';

import '../../../../../base/db/hive_service.dart';

class UserProfileTextFieldWidget extends HookWidget {
  const UserProfileTextFieldWidget({
    super.key,
    required this.textEditingController,
  });

  final TextEditingController textEditingController;
  @override
  Widget build(BuildContext context) {
    final ValueNotifier<bool> isLogin =
       useState(
        MyHiveBoxes.user.get(MyHiveKeys.userIsLoggedIn, defaultValue: false));
    final Size mq = MediaQuery.sizeOf(context);
    return Container(
      width: mq.width * 0.85,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10)),
      child: BlocBuilder<UserDataCubit, UserDataState>(
        builder: (context, userState) {
          return TextField(
            controller: textEditingController,
            style: const TextStyle(
              color: Colors.white,
            ),
            onTapOutside: (_) {
              FocusManager.instance.primaryFocus!.unfocus();
            },
            decoration: InputDecoration(
                prefixIcon: const Icon(
                  HugeIcons.strokeRoundedUser,
                  color: Colors.white,
                ),
                hintStyle: const TextStyle(
                    color: Colors.white24, fontFamily: AppFonts.poppins),
                border: InputBorder.none,
                hintText: isLogin.value ? userState.username : "Enter your name"),
          );
        },
      ),
    ).glassMorphic(blur: 10);
  }
}
