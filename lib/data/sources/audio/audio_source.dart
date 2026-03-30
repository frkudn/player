import 'dart:io';
import 'dart:isolate';
import 'package:color_log/color_log.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;

// ─────────────────────────────────────────────────────────────────────────────
// AUDIO SOURCE
//
// Discovers and scans every mounted storage volume for audio files.
//
// Why the old hard-coded approach broke on many devices:
//   The original code checked exactly three paths:
//     /storage/emulated/0/      — internal storage (always correct)
//     /storage/sdcard1/         — Samsung convention (many phones use this)
//     /storage/extsd/           — old convention (almost never correct)
//
//   Android actually mounts removable volumes at:
//     /storage/<UUID>/          e.g. /storage/1A2B-3C4D/
//   The UUID is assigned by Android at mount time and differs between
//   devices, users, and even re-inserts of the same card.
//
// How we discover volumes correctly:
//   Step 1 — path_provider.getExternalStorageDirectories()
//     Returns the app's sandbox directory on every mounted volume.
//     e.g. [.../Android/data/com.app/files, /storage/1A2B-3C4D/Android/data/...]
//     We walk UP to the volume root (remove /Android/... suffix).
//
//   Step 2 — scan /storage/ directly
//     Lists every subdirectory of /storage/. Emulated storage is at
//     /storage/emulated/0/, SD cards/USB at /storage/<UUID>/.
//     This catches volumes that path_provider misses (e.g. USB OTG on
//     some ROMs that don't register with the MediaStore).
//
//   Step 3 — deduplicate
//     Both methods often return the same volume. We use a Set of canonical
//     real paths to ensure each volume is scanned exactly once.
//
// Scanning is done in parallel isolates — one per volume — so a slow SD
// card never blocks the internal storage results.
// ─────────────────────────────────────────────────────────────────────────────

class AudioSource {
  // ── Supported audio formats ───────────────────────────────────────────────
  // Extension list checked against every file found during scanning.
  // Add new formats here to support additional containers.
  static const List<String> _supportedFormats = [
    '.mp3', // MPEG-1/2 Audio Layer III — most common
    '.flac', // Free Lossless Audio Codec
    '.wav', // Waveform Audio File Format
    '.m4a', // MPEG-4 Audio (AAC in MP4 container)
    '.aac', // Advanced Audio Coding (raw)
    '.ogg', // Ogg Vorbis
    '.opus', // Opus codec in Ogg container — modern, efficient
    '.wma', // Windows Media Audio
    '.alac', // Apple Lossless
    '.ape', // Monkey's Audio lossless
    '.dsf', // DSD Stream File (audiophile)
    '.mka', // Matroska Audio container
    //  '.mp4', // MPEG-4 video container — often contains audio-only files
    //  '.3gp', // 3GPP — common on older Android recordings
  ];

  // ── Directories to skip during recursive scan ─────────────────────────────
  // Android system directories can contain thousands of tiny audio clips
  // (notification sounds, UI sounds) that are not music. Skipping them
  // speeds up scanning significantly and avoids polluting the library.
  static const List<String> _skipDirs = [
    '/Android', // App sandboxes + system files
    '/proc', // Linux virtual filesystem — not real files
    '/sys', // Linux sysfs — not real files
    '/.thumbnails', // Android media thumbnails cache
    '/lost+found', // fsck recovery directory
  ];

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Scans ALL mounted storage volumes for audio files.
  ///
  /// Discovers volumes dynamically — works on internal storage, SD cards,
  /// USB OTG drives, and any other volume Android has mounted.
  ///
  /// Returns a deduplicated list of absolute file paths.
  Future<List<String>> fetchAllAudioFilePaths() async {
    final audioFiles = <String>[];

    try {
      final roots = await _discoverVolumeRoots();
      clog.info('AudioSource: discovered ${roots.length} storage volume(s)');
      for (final r in roots) {
        clog.info('  → $r');
      }

      // Scan each volume in its own isolate — parallel for speed
      final futures = roots.map((r) => _scanInIsolate(r)).toList();
      final results = await Future.wait(futures);

      for (final result in results) {
        audioFiles.addAll(result);
      }

      clog.info('AudioSource: found ${audioFiles.length} audio file(s) total');
    } catch (e) {
      clog.error('AudioSource.fetchAllAudioFilePaths error: $e');
    }

    return audioFiles;
  }

  /// Scans a single specific directory for audio files.
  ///
  /// Used when the user picks a folder manually, or when AudiosBloc needs
  /// to reload a specific directory (e.g. after folder navigation).
  Future<List<String>> fetchAudioFilePathsFromSingleDirectory(
      Directory directory) async {
    try {
      clog.info('AudioSource: scanning single dir → ${directory.path}');
      return await _scanInIsolate(directory.path);
    } catch (e) {
      clog.error(
          'AudioSource.fetchAudioFilePathsFromSingleDirectory error: $e');
      return [];
    }
  }

  // ── Volume discovery ───────────────────────────────────────────────────────

  /// Returns deduplicated root paths of every mounted storage volume.
  ///
  /// Combines two discovery strategies:
  ///   1. path_provider  — reliable for volumes Android registers as external
  ///   2. /storage/ scan — catches USB OTG and volumes some ROMs don't expose
  ///      through the standard APIs
  Future<List<String>> _discoverVolumeRoots() async {
    // Use a set of real (resolved symlink) paths to avoid scanning the same
    // physical volume twice (e.g. /sdcard → /storage/emulated/0)
    final seen = <String>{};
    final roots = <String>[];

    // ── Strategy 1: path_provider ────────────────────────────────────────
    try {
      // getExternalStorageDirectories() returns app-specific subdirectories
      // on every mounted external volume (internal + SD card + USB OTG).
      // We strip the app-specific suffix to get the volume root.
      //
      // Example input:  /storage/1A2B-3C4D/Android/data/com.app/files
      // Example output: /storage/1A2B-3C4D
      final extDirs = await path_provider.getExternalStorageDirectories() ?? [];

      for (final dir in extDirs) {
        final root = _volumeRootFromAppDir(dir.path);
        if (root != null) {
          final realPath = await _realPath(root);
          if (seen.add(realPath)) roots.add(root);
        }
      }

      // Also always include internal storage directly
      final internalRoot = '/storage/emulated/0';
      final internalReal = await _realPath(internalRoot);
      if (await Directory(internalRoot).exists() && seen.add(internalReal)) {
        roots.add(internalRoot);
      }
    } catch (e) {
      clog.warning('path_provider volume discovery failed: $e');
    }

    // ── Strategy 2: scan /storage/ directly ─────────────────────────────
    // Lists every direct child of /storage/. Valid volume mounts are
    // subdirectories (not symlinks, not files).
    //
    // Typical contents of /storage/:
    //   emulated/      — internal storage (we access via emulated/0)
    //   1A2B-3C4D/     — SD card (UUID assigned by Android)
    //   self/          — symlink to current user's emulated storage — skip
    try {
      final storageDir = Directory('/storage');
      if (await storageDir.exists()) {
        await for (final entity in storageDir.list(followLinks: false)) {
          if (entity is! Directory) continue;

          final name = path.basename(entity.path);

          // Skip virtual/symlink entries that aren't real volumes
          if (name == 'self' || name == 'emulated') continue;

          // Validate: directory must exist and be readable
          final volumeRoot =
              entity.path.endsWith('/') ? entity.path : '${entity.path}/';

          if (await Directory(volumeRoot).exists()) {
            // For emulated/0 use the canonical form
            final candidate =
                name == 'emulated' ? '/storage/emulated/0' : entity.path;

            final realPath = await _realPath(candidate);
            if (seen.add(realPath)) {
              roots.add(candidate);
              clog.info(
                  'AudioSource: /storage/ scan found volume → $candidate');
            }
          }
        }
      }
    } catch (e) {
      clog.warning('/storage/ scan failed: $e — this is normal on some ROMs');
    }

    return roots;
  }

  /// Strips the app-specific suffix from a path_provider directory path
  /// to recover the volume root.
  ///
  /// Input:  /storage/1A2B-3C4D/Android/data/com.example.app/files
  /// Output: /storage/1A2B-3C4D
  ///
  /// Returns null if the path doesn't contain the expected Android suffix.
  String? _volumeRootFromAppDir(String appDirPath) {
    // Android always sandboxes app files under Android/data/ or Android/obb/
    const marker = '/Android/';
    final idx = appDirPath.indexOf(marker);
    if (idx == -1) return null;
    return appDirPath.substring(0, idx);
  }

  /// Resolves symlinks to get the canonical real path.
  /// Falls back to the original path if resolution fails.
  Future<String> _realPath(String p) async {
    try {
      return await File(p).resolveSymbolicLinks();
    } catch (_) {
      return p;
    }
  }

  // ── Isolate-based scanning ─────────────────────────────────────────────────

  /// Spawns an isolate to scan [directoryPath] and returns all found paths.
  ///
  /// Running in an isolate means the main thread (and UI) stays responsive
  /// even when scanning a large SD card with tens of thousands of files.
  Future<List<String>> _scanInIsolate(String directoryPath) async {
    final receivePort = ReceivePort();
    try {
      await Isolate.spawn(
        _isolateScanWorker,
        _ScanMessage(
          sendPort: receivePort.sendPort,
          directoryPath: directoryPath,
          supportedFormats: _supportedFormats,
          skipDirs: _skipDirs,
        ),
      );
      final result = await receivePort.first as List<String>;
      return result;
    } catch (e) {
      clog.error('AudioSource._scanInIsolate error for $directoryPath: $e');
      return [];
    } finally {
      receivePort.close();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ISOLATE WORKER
//
// Top-level function required by Isolate.spawn — cannot be a class method.
// Receives a _ScanMessage, performs the recursive scan, and sends results back.
// ─────────────────────────────────────────────────────────────────────────────

/// Message object passed to the isolate.
/// Isolates communicate through ports using sendable objects (no closures,
/// no widget references). A plain data class like this is safe to send.
class _ScanMessage {
  final SendPort sendPort;
  final String directoryPath;
  final List<String> supportedFormats;
  final List<String> skipDirs;

  const _ScanMessage({
    required this.sendPort,
    required this.directoryPath,
    required this.supportedFormats,
    required this.skipDirs,
  });
}

/// Top-level isolate entry point.
void _isolateScanWorker(_ScanMessage msg) {
  final results = <String>[];
  try {
    _recursiveScan(
      directory: Directory(msg.directoryPath),
      results: results,
      supportedFormats: msg.supportedFormats,
      skipDirs: msg.skipDirs,
    );
  } catch (e) {
    // Log but don't crash — send whatever we have so far
    clog.error('_isolateScanWorker error in ${msg.directoryPath}: $e');
  }
  msg.sendPort.send(results);
}

/// Recursively scans [directory], appending audio file paths to [results].
///
/// Performance notes:
///   • listSync is used instead of list (async) because inside an isolate
///     there is no event loop — synchronous I/O is fine and faster.
///   • skipDirs entries are checked with String.contains() against the full
///     path, catching both top-level and nested matches in one check.
///   • followLinks: false avoids infinite loops from circular symlinks.
void _recursiveScan({
  required Directory directory,
  required List<String> results,
  required List<String> supportedFormats,
  required List<String> skipDirs,
}) {
  try {
    // Skip system directories before even listing their contents
    for (final skip in skipDirs) {
      if (directory.path.contains(skip)) return;
    }

    final entities = directory.listSync(recursive: false, followLinks: false);

    for (final entity in entities) {
      if (entity is Directory) {
        _recursiveScan(
          directory: entity,
          results: results,
          supportedFormats: supportedFormats,
          skipDirs: skipDirs,
        );
      } else if (entity is File) {
        final ext = path.extension(entity.path).toLowerCase();
        if (supportedFormats.contains(ext)) {
          results.add(entity.path);
        }
      }
    }
  } catch (e) {
    // Catch per-directory errors (permission denied, I/O error) so one
    // bad folder doesn't abort the entire scan
    clog.error('_recursiveScan error in ${directory.path}: $e');
  }
}
