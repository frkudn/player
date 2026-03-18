import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:open_player/base/strings/app_strings.dart';
import 'package:velocity_x/velocity_x.dart';
import '../../../../../base/strings/app_disclaimer_licenses_strings.dart';
import 'settings_list_tile_widget.dart';

class LicenseWidget extends StatelessWidget {
  const LicenseWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    return SettingsListTileWidget(
      label: "License",
      iconData: Icons.description,
      onTap: () {
        VxDialog.showCustom(context,
            child: [
              SizedBox(
                height: mq.height * 0.7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    'MIT License:\n'.text.size(16).white.bold.make(),
                    AppDisclaimerAndLicensesStrings.mitLicensesEn.text
                        .size(16)
                        .white
                        .make(),
                    // Add more licenses as needed
                  ],
                ).scrollVertical(),
              ),
              [
                CupertinoButton(
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (p0) => const AboutDialog(
                              applicationVersion: AppStrings.appVersion,
                            ));
                  },
                  child: "More Licenses".text.white.make(),
                ),
                CupertinoButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: "Close".text.white.make(),
                ),
              ].row()
            ].column().p16().scrollVertical().glassMorphic(
                width: mq.width * 0.85, height: mq.height * 0.8, blur: 12),
            barrierDismissible: false);
      },
    );
  }
}
