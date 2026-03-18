// user_data_cubit.dart
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:color_log/color_log.dart';
import 'package:open_player/base/services/permissions/app_permission_service.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;
import '../../../../../../base/services/storage/storage_services.dart';
import '../../../../../../data/services/user/user_services.dart';
import 'user_data_state.dart';

/// Manages user data state and operations using BLoC pattern
class UserDataCubit extends Cubit<UserDataState> {
  final UserService _userRepository;
  final StorageService _storageService;

  UserDataCubit({
    required UserService userRepository,
    required StorageService storageService,
  })  : _userRepository = userRepository,
        _storageService = storageService,
        super(UserDataState.initial());

  /// Updates user's profile picture
  /// Returns [Future<void>] that completes when the operation is done
  Future<void> updateProfilePicture(String? imagePath) async {
    if (imagePath == null) return;

    try {
      final hasPermission = await AppPermissionService.storagePermission();
      if (!hasPermission) {
        await AppPermissionService.storagePermission();
        return;
      }

      final String newImagePath = await _processAndSaveImage(imagePath);
      await _userRepository.updateProfilePicture(newImagePath);

      emit(state.copyWith(profileImagePath: newImagePath));
    } catch (e) {
      clog.error(
        'Failed to update profile picture \n $e',
      );
      // You might want to emit an error state here
    }
  }

  /// Updates username
  /// Returns [Future<void>] that completes when the operation is done
  Future<void> updateUsername(String? username) async {
    if (username == null || username.isEmpty) return;

    try {
      final trimmedUsername = username.trim();
      await _userRepository.updateUsername(trimmedUsername);
      emit(state.copyWith(username: trimmedUsername));
    } catch (e) {
      clog.error('Failed to update username\n $e');
    }
  }

  /// Updates user login status
  /// Returns [Future<void>] that completes when the operation is done
  Future<void> updateLoginStatus(bool status) async {
    try {
      await _userRepository.updateLoginStatus(status);
      emit(state.copyWith(isLoggedIn: status));
    } catch (e) {
      clog.error(
        'Failed to update login status\n $e',
      );
    }
  }

  Future<String> _processAndSaveImage(String imagePath) async {
    final Directory appDir = await _storageService.getApplicationDirectory();
    // final String fileName = 'profilePic ${path.extension(imagePath)}';
    final String fileName = 'profilePic $imagePath';

    final String newPath = path.join(appDir.path, fileName);

    final File newImage = await File(newPath).create(recursive: true);
    await File(imagePath).copy(newImage.path);

    clog.debug('New image saved at: ${newImage.path}');
    return newImage.path;
  }
}
