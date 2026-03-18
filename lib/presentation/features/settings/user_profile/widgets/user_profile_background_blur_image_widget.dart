import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_player/base/assets/images/app_images.dart';
import 'package:open_player/presentation/features/settings/user_profile/cubit/user_data/user_data_cubit.dart';
import 'package:open_player/presentation/features/settings/user_profile/cubit/user_data/user_data_state.dart';

class UserProfileBackgroundBlurImageWidget extends StatelessWidget {
  const UserProfileBackgroundBlurImageWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserDataCubit, UserDataState>(
      builder: (context, userState) {
        return ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: userState.profileImagePath == null
              ? Image.asset(
                  height: double.infinity,
                  width: double.infinity,
                  filterQuality: FilterQuality.high,
                  AppImages.defaultProfile,
                  fit: BoxFit.cover,
                )
              : Image.file(
                  height: double.infinity,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  File(userState.profileImagePath!,
                  
                  ),
                ),
        );
      },
    );
  }
}
