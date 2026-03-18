import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UserProfilePageBackButtonWidget extends StatelessWidget {
  const UserProfilePageBackButtonWidget({
    super.key,
  });


  @override
  Widget build(BuildContext context) {
        final Size mq = MediaQuery.sizeOf(context);
    return Positioned(
      left: mq.width * 0.05,
      top: mq.height * 0.02,
      child: SafeArea(
        child: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: IconButton(
            onPressed: () {
              GoRouter.of(context).pop();
            },
            icon: const Icon(
              CupertinoIcons.back,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
