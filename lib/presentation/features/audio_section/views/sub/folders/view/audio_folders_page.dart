// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_player/presentation/features/audio_section/views/sub/folders/widgets/custom_audio_folder_widget.dart';
import 'dart:io';
import 'package:open_player/presentation/features/audio_section/bloc/audio_bloc/audios_bloc.dart';
import 'package:open_player/presentation/shared/widgets/nothing_widget.dart';

class AudioFoldersPage extends StatelessWidget {
  const AudioFoldersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildFoldersList(context);
  }

  /// Builds the list of audio folders using BlocSelector
  ///
  /// Extracts unique directory paths from all songs and displays them
  /// with folder icon, name, and song count
  Widget _buildFoldersList(BuildContext context) {
    return BlocSelector<AudiosBloc, AudiosState, AudiosSuccess?>(
      selector: (state) => state is AudiosSuccess ? state : null,
      builder: (context, state) {
        // If no successful state, return a placeholder widget
        if (state == null) return nothing;

        // Extract unique folder paths
        final List<String> folders = _extractUniqueFolders(state);

        return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: folders.length,
            separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.grey.shade300,
                ),
            itemBuilder: (context, index) =>
                CustomAudioFolderWidget(dirPath: folders[index], state: state));
      },
    );
  }

  /// Extracts unique folder paths from all songs
  List<String> _extractUniqueFolders(AudiosSuccess state) {
    final List<String> folders = [];
    state.allSongs.every((element) {
      final file = File(element.path);
      final dirPath = file.parent.path;
      if (!folders.contains(dirPath)) {
        folders.add(dirPath);
      }
      return true;
    });
    return folders;
  }
}
