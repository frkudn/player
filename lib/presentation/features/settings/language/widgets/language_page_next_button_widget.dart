import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../base/router/router.dart';

class LanguagePageNextButtonWidget extends StatelessWidget {
  const LanguagePageNextButtonWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        context.pushReplacementNamed(AppRoutes.userProfileRoute);
      },
      child: const Text("Next"),
    );
  }
}
