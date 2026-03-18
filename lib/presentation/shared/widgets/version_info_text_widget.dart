import 'package:flutter/material.dart';
import 'package:open_player/base/strings/app_strings.dart';

class VersionInfoTextWidget extends StatelessWidget {
  const VersionInfoTextWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'version ${ AppStrings.appVersion}',
      style: Theme.of(context).textTheme.bodySmall,
    );
    
  }
}