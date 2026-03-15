import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_player/base/assets/images/app_images.dart';
import 'package:open_player/logic/user_data/user_data_cubit.dart';
import 'package:open_player/logic/user_data/user_data_state.dart';
import 'package:open_player/presentation/pages/settings/user_profile/widgets/user_profile_preview.dart';

class UserProfileCircleAvatarWidget extends StatelessWidget {
  const UserProfileCircleAvatarWidget({
    super.key,
    required this.changeButtonOnPressed,
    required this.tempImage,
  });

  final Function()? changeButtonOnPressed;
  final XFile? tempImage;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BlocBuilder<UserDataCubit, UserDataState>(
          builder: (context, userState) {
            return Card(
              shape: const CircleBorder(),
              child: GestureDetector(
                onTap: () {
                  File? file = tempImage != null
                      ? File(tempImage!.path)
                      : File(userState.profileImagePath!);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfilePreview(file: file),
                    ),
                  );
                },
                child: CircleAvatar(
                  minRadius: 60,
                  maxRadius: 90,
                  backgroundImage: tempImage != null
                      ? FileImage(File(tempImage!.path))
                      : userState.profileImagePath != null
                          ? FileImage(File(userState.profileImagePath!))
                          : const AssetImage(AppImages.defaultProfile),
                ),
              ),
            );
          },
        ),

        //-------- Profile Pic Change Button ----------//
        Positioned(
          bottom: 1,
          right: 15,
          child: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: IconButton(
              onPressed: changeButtonOnPressed,
              icon: const Icon(HugeIcons.strokeRoundedImageAdd01),
            ),
          ),
        ),
      ],
    );
  }
}
