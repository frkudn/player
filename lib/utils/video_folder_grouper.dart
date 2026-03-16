// lib/utils/video_folder_grouper.dart

import 'package:open_player/data/models/video_model.dart';
import 'package:path/path.dart' as path;

class VideoFolder {
  final String name;
  final String folderPath;
  final List<VideoModel> videos;

  const VideoFolder({
    required this.name,
    required this.folderPath,
    required this.videos,
  });

  int get count => videos.length;

  VideoModel get coverVideo => videos.first;
}

class VideoFolderGrouper {
  /// Groups a flat list of videos by their parent directory
  static List<VideoFolder> group(List<VideoModel> videos) {
    final Map<String, List<VideoModel>> map = {};

    for (final video in videos) {
      final folderPath = path.dirname(video.path);
      final folderName = path.basename(folderPath);
      map.putIfAbsent(folderName, () => []).add(video);
    }

    return map.entries
        .map((e) => VideoFolder(
              name: e.key,
              folderPath: path.dirname(e.value.first.path),
              videos: e.value,
            ))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}
