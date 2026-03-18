// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';

class SettingsListTileWidget extends StatelessWidget {
  const SettingsListTileWidget({
    super.key,
    required this.iconData,
    required this.label,
    this.onTap,
    this.translation
  });

  final IconData iconData;
  final String label;
  final Map<String, String>? translation;

  final onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(iconData),
      title: Text(
        label
      ),
      onTap: onTap,
    );
  }
}
