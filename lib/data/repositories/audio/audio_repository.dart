import 'dart:io';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:color_log/color_log.dart';
import 'package:open_player/data/models/picture_model.dart';
import 'package:open_player/utils/audio_quality_calculator.dart';
import '../../../base/services/permissions/app_permission_service.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;
import '../../models/audio_model.dart';
import '../../sources/audio/audio_source.dart';
import 'dart:typed_data';
import 'package:murmurhash/murmurhash.dart';

import 'audio_repository_base.dart';

/// Implementation of [AudioRepositoryBase] that handles audio file discovery
/// and metadata extraction.
///
/// Responsibilities:
/// - Scanning device storage for audio files
/// - Reading and parsing audio metadata (title, artist, album, genre, etc.)
/// - Calculating audio quality tier (DSD / MQ / HR / HQ / SQ / LQ)
/// - Creating standardized [AudioModel] objects
/// - Handling all error cases with safe fallback values
class AudioRepository implements AudioRepositoryBase {
  /// Provider that handles low-level audio file operations
  final AudioSource audioProvider;

  AudioRepository(this.audioProvider);

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Retrieves all audio files from device storage.
  ///
  /// Returns an empty list if:
  /// - Storage permission is denied
  /// - No audio files are found
  /// - An error occurs during scanning
  @override
  Future<List<AudioModel>> getAllAudioFiles() async {
    try {
      final bool hasPermission = await AppPermissionService.storagePermission();

      if (!hasPermission) {
        clog.error('Storage permission not granted');
        clog.warning('Retrying storage permission request...');
        await AppPermissionService.storagePermission().then((_) {
          clog.error('Storage permission still not granted');
        });
        return [];
      }

      final List<String> audioPaths =
          await audioProvider.fetchAllAudioFilePaths();

      final List<AudioModel> audios = await Future.wait(
        audioPaths.map((p) => getAudioInfo(p)),
      );

      clog.info('Found ${audios.length} audio files');
      return audios;
    } catch (e) {
      clog.error('Error fetching all audio files: $e');
      return [];
    }
  }

  /// Retrieves audio files from a specific [directory].
  ///
  /// Returns an empty list if:
  /// - Storage permission is denied
  /// - The directory contains no audio files
  /// - An error occurs during scanning
  @override
  Future<List<AudioModel>> getAudioFilesFromSingleDirectory(
      Directory directory) async {
    try {
      final bool hasPermission = await AppPermissionService.storagePermission();

      if (!hasPermission) {
        clog.error('Storage permission not granted');
        clog.warning('Retrying storage permission request...');
        await AppPermissionService.storagePermission().then((_) {
          clog.error('Storage permission still not granted');
        });
        return [];
      }

      final List<String> audioPaths =
          await audioProvider.fetchAudioFilePathsFromSingleDirectory(directory);

      final List<AudioModel> audios = await Future.wait(
        audioPaths.map((p) => getAudioInfo(p)),
      );

      clog.info('Found ${audios.length} audio files in ${directory.path}');
      return audios;
    } catch (e) {
      clog.error('Error fetching audio files from directory: $e');
      return [];
    }
  }

  /// Extracts metadata from the audio file at [audioPath] and returns
  /// a fully populated [AudioModel].
  ///
  /// Falls back to a placeholder model if:
  /// - The file does not exist
  /// - Metadata cannot be read
  /// - Any unexpected error occurs
  @override
  Future<AudioModel> getAudioInfo(String audioPath) async {
    try {
      final File audioFile = File(audioPath);

      if (!await audioFile.exists()) {
        clog.warning('File not found: $audioPath');
        return _createPlaceholderAudioModel(audioPath);
      }

      dynamic metadata;
      try {
        metadata = readMetadata(audioFile, getImage: true);
      } catch (e) {
        clog.warning('Error reading metadata for $audioPath: $e');
        return _createPlaceholderAudioModel(audioPath);
      }

      // ── Extract all metadata fields safely ──────────────────────────────
      final String title = _getSafeTitle(audioPath, metadata);
      final String artists = _getSafeArtist(metadata);
      final String album = _getSafeAlbum(metadata);
      final List<String> genre = _getSafeGenre(metadata);

      final int bitrate = metadata.bitrate ?? 0;
      final int sampleRate = metadata.sampleRate ?? 0;
      final int? bitDepth = _getSafeBitDepth(metadata);
      final String? codec = _getSafeCodec(audioPath, metadata);

      final String quality = _calculateSafeQuality(
        bitrate: bitrate,
        sampleRate: sampleRate,
        codec: codec,
        bitDepth: bitDepth,
      );

      final List<PictureModel> thumbnails = _getSafeThumbnails(metadata);

      return AudioModel(
        title: title,
        ext: path.extension(audioPath),
        path: audioPath,
        size: audioFile.statSync().size,
        thumbnail: thumbnails,
        album: album,
        artists: artists,
        genre: genre,
        bitrate: bitrate,
        lyrics: metadata.lyrics?.trim() ?? "",
        sampleRate: sampleRate,
        language: metadata.language?.trim() ?? "",
        year: metadata.year ?? DateTime(0000),
        quality: quality,
        lastModified: audioFile.lastModifiedSync(),
        lastAccessed: audioFile.lastAccessedSync(),
        id: generateStableAudioId(audioPath),
      );
    } catch (e) {
      clog.error('Error processing audio file $audioPath: $e');
      return _createPlaceholderAudioModel(audioPath);
    }
  }

  // ── Metadata extractors ────────────────────────────────────────────────────

  /// Returns the filename (without extension) as the track title.
  /// Falls back to raw basename if cleanup fails.
  /// TODO: Prefer metadata.title when available and well-formed.
  String _getSafeTitle(String audioPath, dynamic metadata) {
    try {
      final String fileName = path.basenameWithoutExtension(audioPath);
      return _cleanupText(fileName);
    } catch (_) {
      return path.basenameWithoutExtension(audioPath);
    }
  }

  /// Returns the artist string, or "unknown" if absent.
  String _getSafeArtist(dynamic metadata) {
    try {
      final String? artist = metadata.artist;
      return (artist != null && artist.trim().isNotEmpty)
          ? _cleanupText(artist)
          : "unknown";
    } catch (_) {
      return "unknown";
    }
  }

  /// Returns the album string, or "unknown" if absent.
  String _getSafeAlbum(dynamic metadata) {
    try {
      final String? album = metadata.album;
      return (album != null && album.trim().isNotEmpty)
          ? _cleanupText(album)
          : "unknown";
    } catch (_) {
      return "unknown";
    }
  }

  /// Returns the genre list, or an empty list if absent.
  List<String> _getSafeGenre(dynamic metadata) {
    try {
      final genres = metadata.genres;
      if (genres != null && genres is List) {
        return genres
            .map((g) => _cleanupText(g.toString()))
            .where((g) => g.isNotEmpty)
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Returns the bit depth from metadata, or null if unavailable.
  /// Common values: 8, 16, 24, 32.
  int? _getSafeBitDepth(dynamic metadata) {
    try {
      final dynamic bd = metadata.bitDepth;
      if (bd == null) return null;
      final int parsed = bd is int ? bd : int.tryParse(bd.toString()) ?? 0;
      // Sanity-check: valid bit depths are 8 / 16 / 24 / 32
      return (parsed == 8 || parsed == 16 || parsed == 24 || parsed == 32)
          ? parsed
          : null;
    } catch (_) {
      return null;
    }
  }

  /// Returns the codec string for quality calculation.
  ///
  /// Strategy (in priority order):
  /// 1. metadata.format  — most reliable when present
  /// 2. File extension   — reliable fallback (e.g. ".flac" → "flac")
  /// 3. null             — calculator will skip codec-based rules
  String? _getSafeCodec(String audioPath, dynamic metadata) {
    try {
      // 1. Try metadata format field
      final String? fmt = metadata.format?.toString().trim().toLowerCase();
      if (fmt != null && fmt.isNotEmpty) return fmt;

      // 2. Fall back to file extension
      final String ext =
          path.extension(audioPath).toLowerCase().replaceAll('.', '');
      if (ext.isNotEmpty) return ext;

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Calculates the quality tier string.
  /// Returns "unknown" if values are invalid or the calculation fails.
  String _calculateSafeQuality({
    required int bitrate,
    required int sampleRate,
    String? codec,
    int? bitDepth,
  }) {
    try {
      if (bitrate > 0 && sampleRate > 0) {
        return AudioQualityCalculator.calculateQuality(
          bitrate: bitrate,
          sampleRate: sampleRate,
          codec: codec,
          bitDepth: bitDepth,
        );
      }
      return "unknown";
    } catch (e) {
      clog.warning('Quality calculation failed: $e');
      return "unknown";
    }
  }

  /// Extracts embedded album art thumbnails from metadata.
  /// Returns an empty list if none are found or processing fails.
  List<PictureModel> _getSafeThumbnails(dynamic metadata) {
    try {
      if (metadata.pictures != null) {
        return metadata.pictures.map<PictureModel>((e) {
          return PictureModel(
            bytes: e.bytes ?? Uint8List(0),
            mimetype: e.mimetype ?? "image/jpeg",
          );
        }).toList();
      }
      return [];
    } catch (e) {
      clog.warning('Error processing thumbnails: $e');
      return [];
    }
  }

  // ── Utilities ──────────────────────────────────────────────────────────────

  /// Removes control characters and non-printable bytes from [text].
  /// Returns an empty string for null or blank input.
  String _cleanupText(String? text) {
    if (text == null || text.trim().isEmpty) return "";
    return text
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '') // strip control chars
        .trim()
        .replaceAll(RegExp(r'[^\x20-\x7E\x80-\xFF]'), ''); // keep printable
  }

  /// Creates a minimal placeholder [AudioModel] for unreadable files.
  AudioModel _createPlaceholderAudioModel(String audioPath) {
    final File audioFile = File(audioPath);
    return AudioModel(
      title: path.basenameWithoutExtension(audioPath),
      ext: path.extension(audioPath),
      path: audioPath,
      size: audioFile.existsSync() ? audioFile.statSync().size : 0,
      thumbnail: [],
      album: "unknown",
      artists: "unknown",
      genre: [],
      bitrate: 0,
      lyrics: "",
      sampleRate: 0,
      language: "",
      year: DateTime(0000),
      id: generateStableAudioId(audioPath),
      quality: "unknown",
      lastModified: audioFile.existsSync()
          ? audioFile.lastModifiedSync()
          : DateTime.now(),
      lastAccessed: audioFile.existsSync()
          ? audioFile.lastAccessedSync()
          : DateTime.now(),
    );
  }

  // ── ID generation ──────────────────────────────────────────────────────────

  /// Generates a stable numeric ID for an audio file based on its content.
  ///
  /// The ID:
  /// - Stays the same if the file is renamed
  /// - Changes if the file content changes
  /// - Uses MurmurHash3 over the first 4 KB + last 1 KB for speed
  int generateStableAudioId(String audioPath) {
    try {
      final File audioFile = File(audioPath);
      if (!audioFile.existsSync()) return 0;

      final int fileSize = audioFile.lengthSync();
      if (fileSize == 0) return 0;

      final raf = audioFile.openSync();

      // Read first 4 KB
      final startBytes = Uint8List(4 * 1024);
      final int bytesRead = raf.readIntoSync(startBytes);

      // Read last 1 KB (only if file is large enough to avoid overlap)
      Uint8List? endBytes;
      int endBytesRead = 0;
      if (fileSize > 8 * 1024) {
        raf.setPositionSync(fileSize - 1024);
        endBytes = Uint8List(1024);
        endBytesRead = raf.readIntoSync(endBytes);
      }

      raf.closeSync();

      // Build hash key from bytes + file size
      final StringBuffer keyBuffer = StringBuffer();
      keyBuffer.write(String.fromCharCodes(startBytes.sublist(0, bytesRead)));
      keyBuffer.write(fileSize.toString());
      if (endBytes != null) {
        keyBuffer
            .write(String.fromCharCodes(endBytes.sublist(0, endBytesRead)));
      }

      // MurmurHash3 with a fixed prime seed for good distribution
      final int hash = MurmurHash.v3(keyBuffer.toString(), 104729);

      // Ensure positive value
      return hash & 0x7FFFFFFF;
    } catch (e) {
      clog.warning('Error generating audio ID for $audioPath: $e');
      return 0;
    }
  }
}
