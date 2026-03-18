import 'dart:io';

import '../../models/audio_model.dart';

/// Abstract base class defining core functionality for audio file operations.
abstract class AudioRepositoryBase {
  Future<List<AudioModel>> getAllAudioFiles();
  Future<List<AudioModel>> getAudioFilesFromSingleDirectory(
      Directory directory);
  Future<AudioModel> getAudioInfo(String audioPath);
}
