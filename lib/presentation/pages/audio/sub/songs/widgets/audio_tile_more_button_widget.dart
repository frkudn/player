import 'package:color_log/color_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/data/models/audio_model.dart';
import 'package:open_player/data/services/favorite_audio_hive_service/audio_hive_service.dart';
import 'package:open_player/data/services/file_service/file_service.dart';
import 'package:open_player/logic/audio_bloc/audios_bloc.dart';
import 'package:open_player/presentation/common/methods/show_add_to_playlist_modal_bottom_sheet.dart';
import 'package:open_player/presentation/common/widgets/audio_info_sheet/audio_info_sheet_widget.dart';
import 'package:open_player/utils/app_menu.dart';
import 'package:share_plus/share_plus.dart';
import 'package:velocity_x/velocity_x.dart';

class AudioTileMoreButtonWidget extends StatelessWidget {
  const AudioTileMoreButtonWidget(
      {super.key,
      required this.path,
      required this.audio,
      required this.audios,
      required this.isPlaying});
  final bool isPlaying;
  final String path;
  final AudioModel audio;
  final List<AudioModel> audios;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        Offset position = details.globalPosition;
        AppMenuHelper.showPopMenuAtPosition(
            context: context,
            position: position,
            items: [
              _musicAddToFavorite(audio.id),
              _musicAddToPlaylist(context, audio),
              _renameMusic(context, path, audio.title),
              _toggleHideMusic(context, path),
              _deleteMusic(
                context,
                path,
              ),
              _more(context, audio),
              _share(audio),
            ]);
      },
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Icon(
          HugeIcons.strokeRoundedMoreVerticalCircle01,
          color: isPlaying ? Colors.white : null,
        ),
      ),
    );
  }
}

//----------------------------------------------------//
///-----------------  Widgets  --------------------///
///-------------------------------------------------///

///--------------- A D D  T O  F A V O R I T E
PopupMenuItem<dynamic> _musicAddToFavorite(int id) {
  final isFavorite = FavoritesAudioHiveService().getFavoriteStatus(id);
  return PopupMenuItem(
    onTap: () {
      FavoritesAudioHiveService().toggleFavorite(id);
    },
    child: ListTile(
      title: Text(
        isFavorite ? "Remove from Favorites" : "Add to Favorite",
      ),
      trailing:
          Icon(isFavorite ? Icons.favorite : HugeIcons.strokeRoundedFavourite),
    ),
  );
}

///--------------- A D D  T O  P L A Y L I S T
PopupMenuItem<dynamic> _musicAddToPlaylist(
    BuildContext context, AudioModel audio) {
  return PopupMenuItem(
    onTap: () {
      showAddToPlaylistModalBottomSheet(context, audio);
    },
    child: ListTile(
      title: Text(
        "Add to Playlist",
      ),
      trailing: Icon(Icons.playlist_add),
    ),
  );
}

///--------------- R E N A M E
PopupMenuItem<dynamic> _renameMusic(
    BuildContext context, String path, String songTitle) {
  final oldFileName = songTitle;
  final controller = TextEditingController(text: oldFileName);
  return PopupMenuItem(
    onTap: () {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            //-------- Column
            child: [
              Gap(5),
              "Rename".text.bold.xl2.make(),
              VxTextField(
                controller: controller,
              ),
              Gap(10),

              ///------ Buttons Row
              [
                ElevatedButton(
                  onPressed: () {
                    context.pop();
                  },
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      // Rename the file when the "Rename" button is pressed
                      FileService()
                          .renameFile(path, controller.text.trim(), context);

                      // After renaming, refresh the list or UI
                      context.read<AudiosBloc>().add(AudiosLoadAllEvent());
                      context.pop(); // Close the dialog
                    } catch (e) {
                      // Handle any errors during the renaming process
                      clog.error("Error renaming file: ${e.toString()}");

                      VxToast.show(
                        context,
                        msg: "Error renaming file: ${e.toString()}",
                        bgColor: Colors.red,
                        textColor: Colors.white,
                      );
                    }
                  },
                  child: Text("Rename"),
                ),
              ].row(alignment: MainAxisAlignment.spaceBetween),
            ].column(axisSize: MainAxisSize.min),
          ),
        ),
      );
    },
    child: const ListTile(
      title: Text(
        "Rename",
      ),
      trailing: Icon(Icons.text_snippet),
    ),
  );
}

///--------------- T O G G L E  H I D E
PopupMenuItem<dynamic> _toggleHideMusic(BuildContext context, String path) {
  final isHidden = FileService().isFileHidden(path);
  return PopupMenuItem(
    onTap: () async {
      await FileService().toggleHideFile(path);
      context.read<AudiosBloc>().add(AudiosLoadAllEvent());
    },
    child: ListTile(
      title: Text(
        isHidden ? "Unhide" : "Hide",
      ),
      trailing: Icon(isHidden ? Icons.visibility : Icons.visibility_off),
    ),
  );
}

///--------------- D E L E T E
PopupMenuItem<dynamic> _deleteMusic(
  BuildContext context,
  String path,
) {
  return PopupMenuItem(
    onTap: () {
      FileService().deleteFile(path).whenComplete(
        () {
          context.read<AudiosBloc>().add(AudiosLoadAllEvent());

          VxToast.show(context, msg: "Audio Deleted");
        },
      );
    },
    child: const ListTile(
      title: Text(
        "Delete",
      ),
      trailing: Icon(Icons.delete),
    ),
  );
}

///--------------- Share
PopupMenuItem<dynamic> _share(AudioModel audio) {
  return PopupMenuItem(
    onTap: () async {
      await Share.shareXFiles([XFile(audio.path)]);
    },
    child: const ListTile(
      title: Text(
        "Share",
      ),
      trailing: Icon(HugeIcons.strokeRoundedShare01),
    ),
  );
}

///--------------- Show More
PopupMenuItem<dynamic> _more(BuildContext context, AudioModel audio) {
  return PopupMenuItem(
    onTap: () {
      showBottomSheet(
        context: context,
        enableDrag: true,
        showDragHandle: true,
        builder: (context) => AudioInfoSheetWidget(audio: audio),
      );
    },
    child: const ListTile(
      title: Text(
        "Info",
      ),
      trailing: Icon(HugeIcons.strokeRoundedInformationCircle),
    ),
  );
}
