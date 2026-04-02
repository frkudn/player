// ─────────────────────────────────────────────────────────────────────────────
// AUDIO FOLDERS PAGE
//
// Shows every unique folder directory that contains at least one audio file.
//
// Bug fix vs original:
//   The original used every() for its side-effect loop — every() is meant
//   for predicate testing and short-circuits on false, which makes it
//   unreliable for building a list. Replaced with a standard for loop.
//
// UI improvements:
//   • Sticky count header at the top of the list.
//   • Pull-to-refresh reloads all songs.
//   • Better empty state with icon and explanation.
//   • Responsive horizontal padding.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_player/presentation/features/audio_section/views/sub/folders/widgets/custom_audio_folder_widget.dart';
import 'package:open_player/presentation/features/audio_section/bloc/audio_bloc/audios_bloc.dart';
import 'package:open_player/presentation/shared/widgets/nothing_widget.dart';

class AudioFoldersPage extends StatelessWidget {
  const AudioFoldersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    final double hPad = mq.width >= 600 ? mq.width * 0.06 : 14;
    final Color os = Theme.of(context).colorScheme.onSurface;

    return BlocSelector<AudiosBloc, AudiosState, AudiosSuccess?>(
      selector: (state) => state is AudiosSuccess ? state : null,
      builder: (context, state) {
        if (state == null) return nothing;

        final folders = _extractUniqueFolders(state);

        // ── Empty state ─────────────────────────────────────────────────
        if (folders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_off_outlined,
                    size: 60, color: os.withValues(alpha: 0.12)),
                const SizedBox(height: 16),
                Text('No folders found',
                    style: TextStyle(
                      color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('No audio files were discovered',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13)),
              ],
            ),
          );
        }

        // ── Folder list ─────────────────────────────────────────────────
        return RefreshIndicator(
          onRefresh: () async =>
              context.read<AudiosBloc>().add(AudiosLoadAllEvent()),
          child: Scrollbar(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 110),
              itemCount: folders.length + 1, // +1 for the sticky count header
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: os.withValues(alpha: 0.07)),
              itemBuilder: (context, index) {
                // First item is the folder count header
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${folders.length} ${folders.length == 1 ? 'folder' : 'folders'}',
                      style: TextStyle(
                        color: os.withValues(alpha: 0.35),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  );
                }
                return CustomAudioFolderWidget(
                  dirPath: folders[index - 1],
                  state: state,
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Extracts unique parent directory paths from all songs.
  /// Uses a standard for loop — not every() which is for predicate testing.
  List<String> _extractUniqueFolders(AudiosSuccess state) {
    final seen = <String>{};
    final folders = <String>[];

    for (final song in state.allSongs) {
      final dirPath = File(song.path).parent.path;
      if (seen.add(dirPath)) {
        // add() returns true only when the element is new
        folders.add(dirPath);
      }
    }

    // Sort alphabetically so the list is predictable
    folders.sort();
    return folders;
  }
}
