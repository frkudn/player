import 'dart:io';

import 'package:color_log/color_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:open_player/base/assets/images/app_images.dart';
import 'package:open_player/base/router/router.dart';

import '../../../../../settings/user_profile/cubit/user_data/user_data_cubit.dart';
import '../../../../../settings/user_profile/cubit/user_data/user_data_state.dart';

class AppBarProfileImageWidget extends StatelessWidget {
  const AppBarProfileImageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        clog.debug("Profile Avatar is clicked");
        context.push(AppRoutes.userProfileRoute);
      },
      child: BlocBuilder<UserDataCubit, UserDataState>(
        builder: (context, state) {
          return Card(
            color: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            child: CircleAvatar(
              minRadius: 23,
              maxRadius: 28,
              backgroundImage: state.profileImagePath == null
                  ? const AssetImage(AppImages.defaultProfile)
                  : FileImage(File(state.profileImagePath!)),
            ),
          );
        },
      ),
    );
  }
}
