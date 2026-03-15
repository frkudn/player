import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/logic/audio_bloc/audios_bloc.dart';
import 'package:open_player/presentation/common/widgets/audio_tile_widget.dart';
import 'package:velocity_x/velocity_x.dart';

/// Represents the page displaying songs within a specific folder
///
/// Shows a list of songs in the selected directory with refresh and
/// state management capabilities
class FolderSongsPage extends StatelessWidget {
  final String dirName;
  final String dirPath;

  const FolderSongsPage(
      {super.key, required this.dirName, required this.dirPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  /// Creates a custom AppBar with back navigation
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Icon(
          CupertinoIcons.back,
        ),
      ),
      title: Text(
        dirName,
        style: TextStyle(
          fontFamily: AppFonts.poppins,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Builds the body of the page based on AudiosBloc state
  Widget _buildBody(BuildContext context) {
    return BlocBuilder<AudiosBloc, AudiosState>(
      builder: (context, audioState) {
        if (audioState is AudiosSuccess) {
          return _buildSuccessState(context, audioState);
        } else if (audioState is AudiosLoading) {
          return _buildLoadingState();
        } else if (audioState is AudiosFailure) {
          return _buildFailureState(audioState);
        } else if (audioState is AudiosInitial) {
          return _buildInitialState();
        } else {
          return _buildErrorState();
        }
      },
    );
  }

  /// Builds the success state with songs list
  Widget _buildSuccessState(BuildContext context, AudiosSuccess state) {
    // Filter out hidden files and sort songs
    final songs = state.dirSongs
        .where((audio) => !audio.title.startsWith('.'))
        .toList()
      ..sort((a, b) => a.title.compareTo(b.title));

    // Return empty state if no songs
    if (songs.isEmpty) return _buildEmptySongsState(context);

    return Column(
      children: [
        _buildSongsHeader(context, songs.length),
        Expanded(
          child: Scrollbar(
            child: ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) => AudioTileWidget(
                audios: songs,
                index: index,
                state: state,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the header with song count and refresh button
  Widget _buildSongsHeader(BuildContext context, int songsLength) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Found: $songsLength Songs",
            style: TextStyle(
              fontFamily: AppFonts.poppins,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          IconButton(
            onPressed: () {
              context.read<AudiosBloc>().add(
                  AudiosLoadFromDirectoryEvent(directory: Directory(dirPath)));
            },
            icon: Icon(
              HugeIcons.strokeRoundedRefresh,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds an empty state when no songs are found
  Widget _buildEmptySongsState(BuildContext context) {
    return Center(
      child: [
        "No Audios found".text.make(),
        IconButton(
          onPressed: () => context.read<AudiosBloc>().add(AudiosLoadAllEvent()),
          icon: const Icon(HugeIcons.strokeRoundedRefresh),
        ),
      ].column(),
    );
  }

  /// Builds loading state
  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  /// Builds failure state
  Widget _buildFailureState(AudiosFailure state) {
    return Center(
      child: Text(state.message),
    );
  }

  /// Builds initial state
  Widget _buildInitialState() {
    return "Initializing ...".text.makeCentered();
  }

  /// Builds generic error state
  Widget _buildErrorState() {
    return "Something went wrong".text.makeCentered();
  }
}
