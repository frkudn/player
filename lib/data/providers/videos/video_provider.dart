import 'dart:io';
import 'dart:isolate';
import 'package:color_log/color_log.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

class VideoProvider {
  static const _storageChannel =
      MethodChannel('com.furqanuddin.player/storage');

  static const Set<String> _supportedFormats = {
    '.mp4',
    '.avi',
    '.mov',
    '.mkv',
    '.wmv',
    '.flv',
    '.webm',
    '.m4v',
    '.3gp',
    '.ts',
    '.rmvb',
  };

  Future<List<String>> fetchAllVideoFilePaths() async {
    final List<String> videoFiles = [];

    try {
      // ── Get storage roots from Android via platform channel ────────
      final List<String> roots = await _getStorageRoots();

      clog.info('Storage roots found: $roots');

      if (roots.isEmpty) {
        clog.warning('No storage roots found — falling back to internal');
        roots.add('/storage/emulated/0');
      }

      // ── Scan each root in its own isolate (parallel) ───────────────
      final futures = roots.map((r) => _scanInIsolate(r)).toList();
      final results = await Future.wait(futures);

      for (final result in results) {
        videoFiles.addAll(result);
      }

      // ── Deduplicate ────────────────────────────────────────────────
      final seen = <String>{};
      videoFiles.retainWhere((p) => seen.add(path.normalize(p).toLowerCase()));

      clog.info('Total videos found: ${videoFiles.length}');
    } catch (e) {
      clog.error('Error in fetchAllVideoFilePaths: $e');
    }

    return videoFiles;
  }

  // ── Ask Android for all storage volumes ────────────────────────────────

  Future<List<String>> _getStorageRoots() async {
    try {
      final result = await _storageChannel
          .invokeListMethod<String>('getStorageDirectories');
      return result ?? [];
    } on PlatformException catch (e) {
      clog.error('Platform channel error getting storage: ${e.message}');
      return [];
    } catch (e) {
      clog.error('Error getting storage roots: $e');
      return [];
    }
  }

  // ── Isolate scanner ────────────────────────────────────────────────────

  Future<List<String>> _scanInIsolate(String directoryPath) async {
    final receivePort = ReceivePort();
    try {
      await Isolate.spawn(
        _scanVideoFilesIsolate,
        [receivePort.sendPort, directoryPath],
      );
      final result = await receivePort.first as List<String>;
      clog.info('Scanned $directoryPath — found ${result.length} videos');
      return result;
    } catch (e) {
      clog.error('Isolate scan error for $directoryPath: $e');
      return [];
    } finally {
      receivePort.close();
    }
  }
}

// ── Top-level isolate entry — must be outside the class ──────────────────────

void _scanVideoFilesIsolate(List<dynamic> args) {
  final SendPort sendPort = args[0];
  final String rootPath = args[1];
  final List<String> found = [];

  _scanDir(Directory(rootPath), found);
  sendPort.send(found);
}

void _scanDir(Directory dir, List<String> found) {
  try {
    final name = path.basename(dir.path);

    // Skip Android system folders — huge and contain no user media
    if (name == 'Android' ||
        name == '.android_secure' ||
        name == 'obb' ||
        name == 'data' ||
        dir.path.contains('/Android/data/') ||
        dir.path.contains('/Android/obb/')) {
      return;
    }

    for (final entity in dir.listSync(recursive: false, followLinks: false)) {
      if (entity is Directory) {
        _scanDir(entity, found);
      } else if (entity is File) {
        final ext = path.extension(entity.path).toLowerCase();
        if (_kFormats.contains(ext)) {
          found.add(entity.path);
        }
      }
    }
  } catch (_) {
    // Permission denied on some subdirs — skip silently
  }
}

const Set<String> _kFormats = {
  '.mp4',
  '.avi',
  '.mov',
  '.mkv',
  '.wmv',
  '.flv',
  '.webm',
  '.m4v',
  '.3gp',
  '.ts',
  '.rmvb',
};
