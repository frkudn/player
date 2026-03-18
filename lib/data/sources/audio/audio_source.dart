import 'dart:io';
import 'dart:isolate';
import 'package:color_log/color_log.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;

/// A provider class that handles audio file discovery and management.
///
/// This class is responsible for:
/// - Scanning device storage for audio files
/// - Managing file system operations in separate isolates
/// - Filtering supported audio formats
/// - Handling both single directory and full storage scans
class AudioSource {
  /// A list of supported audio file extensions.
  ///
  /// These formats are checked when scanning directories to identify audio files.
  /// Add new formats here to support additional audio file types.
  static const List<String> _supportedFormats = [
    '.mp3', // MPEG-1/2 Audio Layer III
    '.flac', // Free Lossless Audio Codec
    '.wav', // Waveform Audio File Format
    '.m4a', // MPEG-4 Audio
    '.aac', // Advanced Audio Coding
    '.ogg', // Ogg Vorbis Audio
    '.wma' // Windows Media Audio
  ];

  /// Scans all external storage locations for audio files.
  ///
  /// This method:
  /// - Checks multiple storage locations (internal storage, SD card, etc.)
  /// - Uses isolates for parallel scanning to improve performance
  /// - Handles missing or inaccessible directories gracefully
  ///
  /// Returns a list of absolute paths to discovered audio files.
  /// Returns an empty list if no files are found or if an error occurs.
  Future<List<String>> fetchAllAudioFilePaths() async {
    List<String> audioFiles = [];

    // Common storage locations on Android devices
    List<Directory> directories = [
      Directory("/storage/emulated/0/"), // Internal storage
      Directory("/storage/sdcard1/"), // External storage
      Directory("/storage/extsd/") // SD card
    ];

    try {
      // Create parallel scanning tasks
      List<Future<List<String>>> futures = [];

      for (var directory in directories) {
        // Only scan directories that exist
        if (await directory.exists()) {
          clog.info("ExternalStorageDirectory Path: ${directory.path}");
          futures.add(_scanInIsolate(directory.path));
        } else {
          clog.warning("Directory does not exist: ${directory.path}");
        }
      }

      // Combine results from all storage locations
      final results = await Future.wait(futures);
      for (var result in results) {
        audioFiles.addAll(result);
      }
    } catch (e) {
      clog.error('Error in fetchAllAudioFilePaths: ${e.toString()}');
    }

    return audioFiles;
  }

  /// Scans a specific directory for audio files.
  ///
  /// [directory] The directory to scan for audio files.
  ///
  /// This method is useful when you need to scan:
  /// - A user-selected folder
  /// - A specific music directory
  /// - A temporary storage location
  ///
  /// Returns a list of absolute paths to discovered audio files.
  /// Returns an empty list if no files are found or if an error occurs.
  Future<List<String>> fetchAudioFilePathsFromSingleDirectory(
      Directory directory) async {
    List<String> audioFiles = [];

    try {
      clog.info("ExternalStorageDirectory Path: ${directory.path}");
      final result = await _scanInIsolate(directory.path);
      audioFiles.addAll(result);
    } catch (e) {
      clog.error('Error in fetchAudiofilePaths: ${e.toString()}');
    }

    return audioFiles;
  }

  /// Creates and manages an isolate for scanning audio files.
  ///
  /// [directoryPath] The path to scan for audio files.
  ///
  /// This method:
  /// - Creates a new isolate for file system operations
  /// - Sets up communication channels with the isolate
  /// - Handles isolate lifecycle and cleanup
  ///
  /// Returns a Future that completes with the list of discovered audio paths.
  /// The isolate is automatically terminated after scanning is complete.
  Future<List<String>> _scanInIsolate(String directoryPath) async {
    final receivePort = ReceivePort();

    try {
      await Isolate.spawn(
          scanAudioFiles, [receivePort.sendPort, directoryPath]);

      // Wait for and return the isolate's results
      final result = await receivePort.first as List<String>;
      return result;
    } catch (e) {
      clog.error('Error in _scanInIsolate: ${e.toString()}');
      return [];
    } finally {
      receivePort.close();
    }
  }
}

/// Isolate worker function that performs the actual file system scanning.
///
/// [args] A list containing:
/// - [0] SendPort: Port for communicating results back to the main isolate
/// - [1] String: The directory path to scan
///
/// This function runs in a separate isolate to avoid blocking the main thread
/// during intensive file system operations.
void scanAudioFiles(List<dynamic> args) {
  List<String> audioFilePaths = [];
  SendPort sendPort = args[0];
  final directoryPath = args[1];

  try {
    _scanDirectory(Directory(directoryPath), audioFilePaths);
    sendPort.send(audioFilePaths);
  } catch (e) {
    clog.error('Error in scanAudioFiles isolate: $e');
  }
}

/// Recursively scans a directory for audio files.
///
/// [directory] The directory to scan
/// [audioFilePaths] List to store discovered audio file paths
///
/// This function:
/// - Traverses directory structure recursively
/// - Skips Android system directories
/// - Checks file extensions against supported formats
/// - Handles file system errors gracefully
void _scanDirectory(Directory directory, List<String> audioFilePaths) {
  try {
    // Skip Android system directories to improve performance
    if (directory.path.contains('/Android')) return;

    directory.listSync(recursive: false, followLinks: false).forEach((entity) {
      if (entity is Directory) {
        _scanDirectory(entity, audioFilePaths);
      } else if (entity is File) {
        String ext = path.extension(entity.path).toLowerCase();
        if (AudioSource._supportedFormats.contains(ext)) {
          audioFilePaths.add(entity.path);
        }
      }
    });
  } catch (e) {
    clog.error('Error scanning directory ${directory.path}: $e');
  }
}
