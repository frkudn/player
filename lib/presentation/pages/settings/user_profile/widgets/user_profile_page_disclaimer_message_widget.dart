import 'package:flutter/material.dart';
import 'package:open_player/base/strings/app_disclaimer_licenses_strings.dart';
import 'package:open_player/presentation/common/widgets/texty.dart';

class UserProfilePageDisclaimerMessageWidget extends StatelessWidget {
  const UserProfilePageDisclaimerMessageWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.sizeOf(context);
    return SizedBox(
      width: mq.width * 0.85,
      child: const Texty(
        en: AppDisclaimerAndLicensesStrings.disclaimerMessageEn,
        style: TextStyle(color: Colors.white60, fontSize: 13),
      ),
    );
  }
}
