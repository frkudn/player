import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:open_player/data/models/audio_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM AUDIO SOURCE
//
// Wraps just_audio's ProgressiveAudioSource with a MediaItem tag so that
// just_audio_background can display track info and artwork in:
//   • The Android lock-screen / notification media controls
//   • The iOS control center
//   • Android Auto / CarPlay (if configured)
//
// WHY THE THUMBNAIL WAS NOT SHOWING:
//   The original code had artUri commented out. just_audio_background passes
//   the MediaItem to Android's MediaSession API, which then renders the art
//   in the notification. Android's notification system can NOT load image
//   bytes directly — it needs a URI that it can fetch asynchronously.
//
//   Two common approaches:
//     • data: URI  — works on some devices but is unreliable in notifications
//       because Android's Glide/Picasso loader used internally often rejects
//       data URIs that exceed a size threshold.
//     • file: URI  — always works. We write the bytes to the app's cache
//       directory once per unique track (keyed by path hash code) and hand
//       Android a file:// URI. Subsequent plays of the same track reuse the
//       cached file — no redundant I/O.
//
// WHY ONLY THE STOP BUTTON WAS SHOWING:
//   just_audio_background shows Previous / Play-Pause / Next by default.
//   If the notification only showed a Stop button it was because the
//   MediaItem had no id, OR the audio player was in the "stopped" processing
//   state before the source was set. Ensure JustAudioBackground.init() is
//   called in main() BEFORE any AudioPlayer is created, and that
//   androidStopForegroundOnPause is false if you want the notification to
//   persist while paused.
//
// THUMBNAIL CACHE POLICY:
//   Files are named  <pathHashCode>_art  (no extension needed — Android reads
//   the magic bytes to detect the format). They are written to the app's
//   temporary directory, which Android can clear when storage is low. That is
//   fine — the next time the track is played the file is recreated.
// ─────────────────────────────────────────────────────────────────────────────

class CustomAudioSource extends ProgressiveAudioSource {
  final AudioModel audioModel;

  CustomAudioSource({
    required this.audioModel,
    Map<String, String>? headers,
    ProgressiveAudioSourceOptions? options,
  }) : super(
          Uri.file(audioModel.path),
          headers: headers ?? {'hashcode': audioModel.path.hashCode.toString()},
          tag: MediaItem(
            // id must be unique — use the file path
            id: audioModel.path,
            album: audioModel.album.isNotEmpty
                ? audioModel.album
                : 'Unknown Album',
            title: audioModel.title.isNotEmpty
                ? audioModel.title
                : 'Unknown Title',
            genre: audioModel.genre.isNotEmpty ? audioModel.genre.first : null,
            artist: audioModel.artists.isNotEmpty
                ? audioModel.artists
                : 'Unknown Artist',
            // artUri — the resolved file URI for the cached artwork.
            // Null-safe: returns null when no thumbnail is embedded, in which
            // case just_audio_background shows the default app icon.
            artUri: _resolveArtUri(audioModel),
          ),
          options: options ??
              const ProgressiveAudioSourceOptions(
                androidExtractorOptions: AndroidExtractorOptions(
                  // Enables accurate seeking even for constant-bitrate files
                  // that don't have a seek table (common in .mp3)
                  constantBitrateSeekingAlwaysEnabled: true,
                ),
                darwinAssetOptions: DarwinAssetOptions(
                  preferPreciseDurationAndTiming: true,
                ),
              ),
        );

  // ── Playlist factory ────────────────────────────────────────────────────────
  // Creates a ConcatenatingAudioSource from a list of AudioModel objects.
  // Used by AudioPlayerBloc when initializing playback of a song list.
  static ConcatenatingAudioSource createPlaylist(List<AudioModel> audioList) {
    return ConcatenatingAudioSource(
      children: audioList
          .map((audio) => CustomAudioSource(audioModel: audio))
          .toList(),
    );
  }

  // ── Convenience accessors ───────────────────────────────────────────────────

  AudioModel get model => audioModel;
  String get title => audioModel.title;
  String get extension => audioModel.ext;
  String get filePath => audioModel.path;
  int get size => audioModel.size;
}

// ─────────────────────────────────────────────────────────────────────────────
// ART URI RESOLVER
//
// Writes thumbnail bytes to a temp file and returns a file:// URI.
//
// This function is synchronous because it's called from a constructor super()
// chain — we can't await there. File.writeAsBytesSync() is fine here because:
//   1. It's called once per unique track, not on every frame.
//   2. The cache file is typically small (< 200 KB) so the sync write
//      completes in < 1 ms and does not block the UI thread noticeably.
//   3. Using existsSync() before writing avoids re-writing cached files.
//
// If anything fails (e.g. storage full, permissions denied) we catch the
// error and return null so playback still works — just without artwork.
// ─────────────────────────────────────────────────────────────────────────────

Uri? _resolveArtUri(AudioModel audio) {
  try {
    // Guard: no embedded artwork in this audio file
    if (audio.thumbnail.isEmpty) return null;
    final bytes = audio.thumbnail.first.bytes;
    if (bytes.isEmpty) return null;

    // Use Directory.systemTemp synchronously — available on Android/iOS
    // without async path_provider lookup.
    final cacheDir = Directory.systemTemp;

    // Filename: hash of the audio file path ensures per-track caching.
    // Two different files with the same name hash to the same cache file —
    // extremely unlikely with int hashCode on a full file path.
    final artFile = File(
      '${cacheDir.path}/${audio.path.hashCode.abs()}_art',
    );

    // Only write if not already cached (avoids redundant I/O on replays)
    if (!artFile.existsSync()) {
      artFile.writeAsBytesSync(bytes, flush: true);
    }

    return Uri.file(artFile.path);
  } catch (_) {
    // Swallow — artwork is non-critical, playback must continue
    return null;
  }
}
