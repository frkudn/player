// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/logic/audio_bloc/audios_bloc.dart';
import 'package:open_player/presentation/pages/audio/sub/folders/widgets/folder_songs_page.dart';
import 'package:path/path.dart' as path;
import 'package:velocity_x/velocity_x.dart';

class CustomAudioFolderWidget extends StatelessWidget {
  const CustomAudioFolderWidget(
      {super.key, required this.dirPath, required this.state});

  final String dirPath;
  final AudiosSuccess state;

  @override
  Widget build(BuildContext context) {
    final dirName = path.basename(dirPath);

    final songsInFolder = state.allSongs.where((song) {
      final file = File(song.path);
      return file.parent.path == dirPath;
    }).length;

    return ListTile(
      contentPadding: EdgeInsets.zero,

      //-------- OnTap
      onTap: () {
        context
            .read<AudiosBloc>()
            .add(AudiosLoadFromDirectoryEvent(directory: Directory(dirPath)));

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FolderSongsPage(
              dirName: dirName,
              dirPath: dirPath,
            ),
          ),
        );
      },

      //------- Folder Icon
      leading: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.all(10),
        child: Icon(
          HugeIcons.strokeRoundedFolder03,
          color: Theme.of(context).primaryColor,
          size: 28,
        ),
      ),
      //------Title
      title: dirName.text.light.size(16).make(),
      //-------- Songs Count
      trailing: '$songsInFolder Songs'
          .text
          .size(12)
          .gray400
          .tight
          .make()
          .pSymmetric(h: 8, v: 4)
          .glassMorphic(
              circularRadius: 15,
              blur: 25,
              shadowStrength: 3,
              border: Border.all(color: Colors.black12)),
    );
  }
}
