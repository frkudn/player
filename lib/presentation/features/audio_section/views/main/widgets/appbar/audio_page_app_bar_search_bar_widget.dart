import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:open_player/base/router/router.dart';
import 'package:open_player/presentation/features/local_audio_player/bloc/audio_player_bloc.dart';
import 'package:open_player/presentation/shared/widgets/nothing_widget.dart';

class AudioPageAppBarSearchBarWidget extends StatelessWidget {
  const AudioPageAppBarSearchBarWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final double mqWidth = MediaQuery.sizeOf(context).width;
    final double mqHeight = MediaQuery.sizeOf(context).height;
    return BlocSelector<AudioPlayerBloc, AudioPlayerState,
        AudioPlayerSuccessState?>(
      selector: (state) => state is AudioPlayerSuccessState ? state : null,
      builder: (context, state) {
        if (state == null) {
          return GestureDetector(
            onTap: () {
              context.push(AppRoutes.searchAudiosRoute);
            },
            child: Padding(
              padding: EdgeInsets.only(
                left: mqWidth * 0.01,
                right: mqWidth * 0.01,
              ),
              child: Card(
                child: Container(
                  height: mqHeight * 0.05,
                  width: mqWidth,
                  decoration: BoxDecoration(),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(Icons.search),
                        Text(
                          "  Search songs",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        } else {
          return nothing;
        }
      },
    );
  }
}
