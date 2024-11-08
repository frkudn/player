import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_player/base/router/router.dart';


class AudioPageAppBarSearchButtonWidget extends StatelessWidget {
  const AudioPageAppBarSearchButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IconButton(
        iconSize: 45,
        onPressed: () {
           context.push(AppRoutes.searchAudiosRoute);
        },
        icon: const Icon(CupertinoIcons.search_circle),
      ),
    );
  }
}
