// audio_search_app_bar_widget.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_player/base/strings/app_strings.dart';
import 'package:open_player/utils/extensions.dart';
import 'package:velocity_x/velocity_x.dart';

class AudioSearchAppBarWidget extends StatelessWidget {
  const AudioSearchAppBarWidget({
    super.key,
    required this.query,
    required this.onFilterTap,
  });

  final ValueNotifier<String> query;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
        //-- Language Code
    final String lc = context.languageCubit.state.languageCode;
    final mediaQuery = MediaQuery.sizeOf(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: mediaQuery.width * 0.03,
        vertical: 8,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        shadowColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : null,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  context.pop();
                  query.value = "";
                },
                icon: const Icon(CupertinoIcons.back),
              ),
              Expanded(
                child: VxTextField(
                  autofocus: true,
                  onChanged: (search) => query.value = search.toLowerCase(),
                  hint: AppStrings.searchBy[lc],
                  borderType: VxTextFieldBorderType.none,
                  fillColor: Colors.transparent,
                ),
              ),
              IconButton(
                onPressed: onFilterTap,
                icon: const Icon(Icons.filter_list),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
