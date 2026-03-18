import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_player/base/db/hive_service.dart';
import 'package:open_player/presentation/features/settings/user_profile/widgets/user_profile_background_blur_image_widget.dart';
import 'package:open_player/presentation/features/settings/user_profile/widgets/user_profile_circle_avatar_widget.dart';
import 'package:open_player/presentation/features/settings/user_profile/widgets/user_profile_page_back_button_widget.dart';
import 'package:open_player/presentation/features/settings/user_profile/widgets/user_profile_page_disclaimer_message_widget.dart';
import 'package:open_player/presentation/features/settings/user_profile/widgets/user_profile_page_save_button.dart';
import 'package:open_player/presentation/features/settings/user_profile/widgets/user_profile_text_field_widget.dart';

class UserProfilePage extends HookWidget {
  UserProfilePage({super.key});

 final TextEditingController usernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<XFile?> tempImage = useState(null);
    bool isLogin =
        MyHiveBoxes.user.get(MyHiveKeys.userIsLoggedIn, defaultValue: false);
    final Size mq = MediaQuery.sizeOf(context);
    return Scaffold(
      body: Stack(
        children: [
          //---------- Background Image -----------///
          const UserProfileBackgroundBlurImageWidget(),

          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                //-------- Circular  Profile Avatar --------------///
                UserProfileCircleAvatarWidget(
                  tempImage: tempImage.value,
                  //-------- Change Image Button Clicked ------------//
                  changeButtonOnPressed: () async {
                    final imagePicker = ImagePicker();
                    XFile? pickedImage = await imagePicker.pickImage(
                        source: ImageSource.gallery);
                    tempImage.value = pickedImage;
                  },
                ),
                const Gap(40),
                //-------- Text Field --------------///
                UserProfileTextFieldWidget(
                  textEditingController: usernameController,
                ),
                const Gap(20),
                //-------------------- Save Button-------------------///
                UserProfilePageSaveButton(
                    tempImage: tempImage.value,
                    usernameController: usernameController,
                    isLogin: isLogin,
                    mq: mq),
                const Gap(20),

                //-------------- Disclaimer Message
                const UserProfilePageDisclaimerMessageWidget(),
              ],
            ),
          ),

          //-------------- BackButton ------------///
          if (isLogin) const UserProfilePageBackButtonWidget(),
        ],
      ),
    );
  }
}
