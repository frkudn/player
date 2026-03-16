import 'dart:io';
import 'dart:typed_data';
import 'package:color_log/color_log.dart';
import 'package:open_player/data/providers/videos/video_provider.dart';
import '../../../base/services/permissions/app_permission_service.dart';
import 'package:path/path.dart' as path;
import '../../models/video_model.dart';

abstract class VideoRepositoryBase {
  Future<List<VideoModel>> getVideoFiles();
  Future<VideoModel> getVideoInfo(String videoPath);
}

class VideoRepository implements VideoRepositoryBase {
  final VideoProvider videoProvider;

  VideoRepository(this.videoProvider);

  @override
  Future<List<VideoModel>> getVideoFiles() async {
    try {
      final bool hasPermission = await AppPermissionService.storagePermission();

      if (!hasPermission) {
        clog.error('Storage permission not granted');
        await AppPermissionService.storagePermission().then((_) {
          clog.error('Storage permission denied on second attempt');
        });
        return [];
      }

      final List<String> videosPath =
          await videoProvider.fetchAllVideoFilePaths();

      // Process in batches of 20 to avoid memory spikes
      final List<VideoModel> videos = [];
      const batchSize = 20;

      for (int i = 0; i < videosPath.length; i += batchSize) {
        final end = (i + batchSize).clamp(0, videosPath.length);
        final batch = videosPath.sublist(i, end);
        final batchResults = await Future.wait(
          batch.map((p) => getVideoInfo(p)),
        );
        videos.addAll(batchResults);
      }

      clog.info('Processed ${videos.length} videos');
      return videos;
    } catch (e) {
      clog.error('Error fetching video files: $e');
      return [];
    }
  }

  @override
  Future<VideoModel> getVideoInfo(String videoPath) async {
    try {
      final File videoFile = File(videoPath);

      // ── Optional thumbnail using video_compress ───────────────────
      // Uncomment the block below if you add video_compress to pubspec.yaml:
      //
      // Uint8List? thumbnail;
      // try {
      //   final result = await VideoCompress.getByteThumbnail(
      //     videoPath,
      //     quality: 25,          // low quality = fast + small
      //     position: -1,         // -1 = auto pick frame
      //   );
      //   thumbnail = result;
      // } catch (_) {
      //   thumbnail = null;
      // }

      return VideoModel(
        title: path.basenameWithoutExtension(videoPath),
        ext: path.extension(videoPath),
        path: videoPath,
        fileSize: videoFile.statSync().size,
        lastAccessed: videoFile.lastAccessedSync(),
        lastModified: videoFile.lastModifiedSync(),
        thumbnail: null, // replace with `thumbnail` when enabled
      );
    } catch (e) {
      clog.error('Error getting video info for $videoPath: $e');
      return VideoModel(
        title: path.basenameWithoutExtension(videoPath),
        ext: path.extension(videoPath),
        path: videoPath,
        fileSize: 0,
        lastAccessed: DateTime.now(),
        lastModified: DateTime.now(),
        thumbnail: null,
      );
    }
  }
}
