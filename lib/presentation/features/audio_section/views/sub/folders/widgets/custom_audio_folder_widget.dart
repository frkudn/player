import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/presentation/features/audio_section/bloc/audio_bloc/audios_bloc.dart';
import 'package:open_player/presentation/features/audio_section/views/sub/folders/widgets/folder_songs_page.dart';
import 'package:path/path.dart' as path;

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM AUDIO FOLDER WIDGET
//
// A single folder row. Tapping it triggers an AudiosLoadFromDirectoryEvent
// then opens FolderSongsPage.
//
// Design improvements:
//   • Folder icon is inside a primary-colored pill badge — more distinctive.
//   • Song count is a compact chip on the right — easier to scan.
//   • Uses Material + InkWell for proper ripple containment.
//   • Folder name text uses Expanded so long paths never overflow.
//   • Subtitle shows the full path in a smaller muted style for power users.
// ─────────────────────────────────────────────────────────────────────────────

class CustomAudioFolderWidget extends StatelessWidget {
  const CustomAudioFolderWidget({
    super.key,
    required this.dirPath,
    required this.state,
  });

  final String dirPath;
  final AudiosSuccess state;

  @override
  Widget build(BuildContext context) {
    final Color pr = Theme.of(context).colorScheme.primary;
    final Color os = Theme.of(context).colorScheme.onSurface;
    final String dirName = path.basename(dirPath);

    // Count songs in this folder — done once per build, not per frame
    final int songCount = state.allSongs.where((song) {
      return File(song.path).parent.path == dirPath;
    }).length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Load the directory's songs into AudiosBloc then navigate
          context.read<AudiosBloc>().add(
                AudiosLoadFromDirectoryEvent(directory: Directory(dirPath)),
              );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FolderSongsPage(
                dirName: dirName,
                dirPath: dirPath,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              // ── Folder icon badge ──────────────────────────────────
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: pr.withValues(alpha: 0.1),
                ),
                child: Icon(
                  HugeIcons.strokeRoundedFolder03,
                  color: pr,
                  size: 22,
                ),
              ),

              const SizedBox(width: 14),

              // ── Folder name + path ─────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dirName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppFonts.poppins,
                        color: os,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Full path in muted small text — useful for folders
                    // with identical names in different directories
                    Text(
                      dirPath,
                      style: TextStyle(
                        fontSize: 10,
                        color: os.withValues(alpha: 0.3),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ── Song count chip ────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: pr.withValues(alpha: 0.08),
                  border:
                      Border.all(color: pr.withValues(alpha: 0.18), width: 1),
                ),
                child: Text(
                  '$songCount',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: pr.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
