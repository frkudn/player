import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:color_log/color_log.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../../../../../data/models/audio_model.dart';
import '../../../../../data/repositories/audio/audio_repository.dart';
part 'audios_event.dart';
part 'audios_state.dart';

// Bloc
class AudiosBloc extends Bloc<AudiosEvent, AudiosState> {
  final AudioRepository audioRepository;
  List<AudioModel> cacheAudioModelList = [];
  Map<String, List<AudioModel>> cachedFoldersAudioModelMap = {};

  AudiosBloc({required this.audioRepository}) : super(AudiosInitial()) {
    on<AudiosLoadAllEvent>(_onLoadAllAudios);
    on<AudiosLoadFromDirectoryEvent>(_onLoadDirectoryAudios);
  }

  Future<void> _onLoadAllAudios(
    AudiosLoadAllEvent event,
    Emitter<AudiosState> emit,
  ) async {
    try {
      emit(AudiosLoading());
      if (cacheAudioModelList.isEmpty) {
        cacheAudioModelList = await audioRepository.getAllAudioFiles();
        emit(AudiosSuccess(allSongs: cacheAudioModelList, dirSongs: []));
      } else {
        emit(AudiosSuccess(allSongs: cacheAudioModelList, dirSongs: []));

        final freshList = await audioRepository.getAllAudioFiles();
        if (!listEquals(cacheAudioModelList, freshList)) {
          cacheAudioModelList = freshList;
          emit(AudiosSuccess(allSongs: cacheAudioModelList, dirSongs: []));
        }
      }
    } catch (e) {
      clog.error('Error in AudiosBloc: $e');
      emit(AudiosFailure(e.toString()));
    }
  }

  FutureOr<void> _onLoadDirectoryAudios(
      AudiosLoadFromDirectoryEvent event, Emitter<AudiosState> emit) async {
    try {
      emit(AudiosLoading());

      if (!cachedFoldersAudioModelMap.containsKey(event.directory.path)) {
        final dirSongs = await audioRepository
            .getAudioFilesFromSingleDirectory(event.directory);

        emit(AudiosSuccess(allSongs: cacheAudioModelList, dirSongs: dirSongs));

        cachedFoldersAudioModelMap[event.directory.path] = dirSongs;
      } else {
        final dirSongs = cachedFoldersAudioModelMap[event.directory.path]!;
        emit(AudiosSuccess(allSongs: cacheAudioModelList, dirSongs: dirSongs));

        final freshList = await audioRepository
            .getAudioFilesFromSingleDirectory(event.directory);
        if (!listEquals(
            cachedFoldersAudioModelMap[event.directory.path], freshList)) {
          cachedFoldersAudioModelMap[event.directory.path] = freshList;
          emit(AudiosSuccess(
              allSongs: cacheAudioModelList, dirSongs: freshList));
        }
      }
    } catch (e) {
      clog.error('Error in AudiosBloc: $e');
      emit(AudiosFailure(e.toString()));
    }
  }
}
