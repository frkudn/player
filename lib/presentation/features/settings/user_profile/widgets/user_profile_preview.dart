import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:open_player/base/assets/images/app_images.dart';
import 'package:velocity_x/velocity_x.dart';

class UserProfilePreview extends StatelessWidget {
  const UserProfilePreview({super.key, this.file, this.bytes});
  final File? file;
  final Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        title: IconButton(
            color: Colors.white,
            onPressed: () {
              context.pop();
            },
            icon: Icon(CupertinoIcons.back)),
      ),
      body: VxZoom(
        twoTouchOnly: true,
        child: Center(
          child: file != null
              ? Image.file(file!)
              : bytes != null
                  ? Image.memory(bytes!)
                  : Image.asset(AppImages.defaultProfile),
        ),
      ),
    );
  }
}
