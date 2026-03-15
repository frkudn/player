import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/base/assets/fonts/styles.dart';

class ViewDirectoryPage extends StatelessWidget {
  const ViewDirectoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: CustomScrollView(
      slivers: [
        const SliverAppBar(
          title: ListTile(
            title: Text("Directory View"),
            subtitle: Text("Path/Directory/Hello"),
          ),
          floating: true,
        ),
        SliverList.builder(
          itemCount: 20,
          itemBuilder: (context, index) => ListTile(
            title: ListTile(
              leading: Icon(
                HugeIcons.strokeRoundedFolder03,
                color: Theme.of(context).primaryColor,
              ),
              title: Text("Title $index", style: const TextStyle(fontFamily: AppFonts.poppins),),
            ),
          ),
        ),
      ],
    ));
  }
}
