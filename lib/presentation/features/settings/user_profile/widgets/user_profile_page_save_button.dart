import 'package:color_log/color_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/base/db/hive_service.dart';
import 'package:open_player/presentation/features/settings/user_profile/cubit/user_data/user_data_cubit.dart';
import '../../../../../base/router/router.dart';
import '../../../audio_section/bloc/audio_bloc/audios_bloc.dart';

class UserProfilePageSaveButton extends StatelessWidget {
  const UserProfilePageSaveButton({
    super.key,
    required this.tempImage,
    required this.usernameController,
    required this.isLogin,
    required this.mq,
  });

  final XFile? tempImage;
  final TextEditingController usernameController;
  final bool isLogin;
  final Size mq;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        // 1. Debug log indicating the button was clicked
        clog.debug("Save Profile Button is clicked!");

        // 2. Update user profile data (username and profile picture)
        updatingUserProfileData(context);

        // 3. Check if this is not a login scenario
        if (!isLogin) {
          // 4. Mark user as logged in by storing a flag in Hive database
          userIsLoggedIn();

          // 6. Navigate to the main page of the app
          _navigateToMainPage(context);

          loadMedia(context);
        } else {
          // 8. If it's a login scenario, simply pop the current screen
          context.pop();
        }
      },
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        fixedSize: Size(
          mq.width * 0.85,
          50,
        ),
      ),
      child: Text(
        isLogin ? "Save" : "Continue to Player",
        style: const TextStyle(
          fontFamily: AppFonts.poppins,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void updatingUserProfileData(BuildContext context) {
    context.read<UserDataCubit>().updateProfilePicture(tempImage?.path);
    context.read<UserDataCubit>().updateUsername(usernameController.text);
  }

  _navigateToMainPage(BuildContext context) {
    context.pushReplacement(AppRoutes.mainRoute);
  }

  userIsLoggedIn() async {
    await MyHiveBoxes.user.put(MyHiveKeys.userIsLoggedIn, true);
  }

  loadMedia(BuildContext context) {
    context.read<AudiosBloc>().add(AudiosLoadAllEvent());
  }
}
