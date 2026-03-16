import 'package:color_log/color_log.dart';
import 'package:open_player/base/db/hive_service.dart';

class FavoritesAudioHiveService {
  final _box = MyHiveBoxes.favoriteAudios;

  /// Adds the audio to favorites.
  Future<void> _addToFavorite(int audioId) async {
    try {
      await _box.put(audioId, true);
    } catch (e) {
      // Log the error if something goes wrong
      clog.error("Error adding audio to favorites: ${e.toString()}");
    }
  }

  /// Removes the audio from favorites.
  Future<void> _removeFromFavorite(int audioId) async {
    try {
      await _box.put(audioId, false);
    } catch (e) {
      // Log the error if something goes wrong
      clog.error("Error removing audio from favorites: ${e.toString()}");
    }
  }

  /// Checks if the audio is in the favorites list.
  Future<bool> _checkIsContain(int audioId) async {
    try {
      return _box.containsKey(audioId);
    } catch (e) {
      clog.error("Error checking if audio is in favorites: ${e.toString()}");
      return false; // In case of error, assume it's not in favorites
    }
  }

  /// Gets the favorite status of the audio.
  bool getFavoriteStatus(int audioId) {
    try {
      bool v = _box.get(audioId, defaultValue: false);
      return v;
    } catch (e) {
      clog.error(
          "Error getting favorite status for audio $audioId: ${e.toString()}");
      return false; // Return false in case of any error
    }
  }

  /// Toggles the favorite status of the audio.
  Future<void> toggleFavorite(int audioId) async {
    try {
      bool isContained = await _checkIsContain(audioId);

      if (isContained) {
        bool currentStatus = getFavoriteStatus(audioId);
        if (currentStatus) {
          await _removeFromFavorite(audioId);
        } else {
          await _addToFavorite(audioId);
        }
      } else {
        // If audio is not in the box, add it to favorites
        await _addToFavorite(audioId);
      }
    } catch (e) {
      clog.error(
          "Error toggling favorite status for audio $audioId: ${e.toString()}");
    }
  }
}
