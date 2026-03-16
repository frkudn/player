// lib/data/services/equalizer_service/equalizer_service.dart
import 'package:flutter/services.dart';

class EqualizerService {
  static const _channel = MethodChannel('com.furqanuddin.player/equalizer');

  static final EqualizerService _instance = EqualizerService._();
  factory EqualizerService() => _instance;
  EqualizerService._();

  Future<bool> init(int audioSessionId) async {
    try {
      return await _channel
              .invokeMethod('init', {'audioSessionId': audioSessionId}) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<int> getNumberOfBands() async =>
      await _channel.invokeMethod('getNumberOfBands') ?? 0;

  Future<List<int>> getBandFreqRange(int band) async {
    final result =
        await _channel.invokeMethod('getBandFreqRange', {'band': band});
    return (result as List).cast<int>();
  }

  Future<int> getBandLevel(int band) async =>
      await _channel.invokeMethod('getBandLevel', {'band': band}) ?? 0;

  Future<void> setBandLevel(int band, int level) async => await _channel
      .invokeMethod('setBandLevel', {'band': band, 'level': level});

  Future<List<int>> getBandLevelRange() async {
    final result = await _channel.invokeMethod('getBandLevelRange');
    return (result as List).cast<int>();
  }

  Future<int> getNumberOfPresets() async =>
      await _channel.invokeMethod('getNumberOfPresets') ?? 0;

  Future<String> getPresetName(int preset) async =>
      await _channel.invokeMethod('getPresetName', {'preset': preset}) ?? '';

  Future<void> usePreset(int preset) async =>
      await _channel.invokeMethod('usePreset', {'preset': preset});

  Future<void> setBassBoost(int strength) async =>
      await _channel.invokeMethod('setBassBoost', {'strength': strength});

  Future<void> setVirtualizer(int strength) async =>
      await _channel.invokeMethod('setVirtualizer', {'strength': strength});

  Future<void> setEnabled(bool enabled) async =>
      await _channel.invokeMethod('setEnabled', {'enabled': enabled});

  Future<void> release() async => await _channel.invokeMethod('release');
}
