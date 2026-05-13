import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mimo_tts_service.dart';
import '../services/audio_service.dart';
import '../services/local_server_service.dart';
import '../services/storage_service.dart';
import 'storage_provider.dart';
import 'tts_provider.dart';
import 'audio_provider.dart';
import 'server_provider.dart';

@immutable
class HomeState {
  final String selectedVoice;
  final bool optimizeTextPreview;
  final bool isGenerating;
  final String? cloneAudioPath;
  final String? cloneAudioBase64;
  final List<int>? currentAudioBytes;

  const HomeState({
    this.selectedVoice = '冰糖',
    this.optimizeTextPreview = false,
    this.isGenerating = false,
    this.cloneAudioPath,
    this.cloneAudioBase64,
    this.currentAudioBytes,
  });

  HomeState copyWith({
    String? selectedVoice,
    bool? optimizeTextPreview,
    bool? isGenerating,
    String? cloneAudioPath,
    bool clearCloneAudioPath = false,
    String? cloneAudioBase64,
    bool clearCloneAudioBase64 = false,
    List<int>? currentAudioBytes,
    bool clearCurrentAudioBytes = false,
  }) {
    return HomeState(
      selectedVoice: selectedVoice ?? this.selectedVoice,
      optimizeTextPreview: optimizeTextPreview ?? this.optimizeTextPreview,
      isGenerating: isGenerating ?? this.isGenerating,
      cloneAudioPath: clearCloneAudioPath ? null : (cloneAudioPath ?? this.cloneAudioPath),
      cloneAudioBase64: clearCloneAudioBase64 ? null : (cloneAudioBase64 ?? this.cloneAudioBase64),
      currentAudioBytes: clearCurrentAudioBytes ? null : (currentAudioBytes ?? this.currentAudioBytes),
    );
  }
}

class HomeStateNotifier extends StateNotifier<HomeState> {
  final MimoTtsService _ttsService;
  final AudioService _audioService;
  final StorageService _storage;
  final LocalServerService _server;

  HomeStateNotifier(
    this._ttsService,
    this._audioService,
    this._storage,
    this._server,
  ) : super(const HomeState());

  void updateVoice(String voice) {
    state = state.copyWith(selectedVoice: voice);
  }

  void updateOptimizeTextPreview(bool value) {
    state = state.copyWith(optimizeTextPreview: value);
  }

  void updateCloneFile({String? path, String? base64}) {
    state = state.copyWith(
      cloneAudioPath: path,
      cloneAudioBase64: base64,
    );
  }

  Future<TtsResult?> generate({
    required String model,
    required String text,
    String? styleInstruction,
  }) async {
    if (_storage.apiKey.isEmpty) return null;

    state = state.copyWith(isGenerating: true);

    try {
      final result = await _ttsService.synthesize(
        apiKey: _storage.apiKey,
        model: model,
        text: text,
        styleInstruction: styleInstruction,
        voice: model == 'mimo-v2.5-tts' ? state.selectedVoice : null,
        voiceCloneBase64: state.cloneAudioBase64,
        optimizeTextPreview: state.optimizeTextPreview,
      );

      await _audioService.play(result.audioBytes, format: result.format);
      state = state.copyWith(
        isGenerating: false,
        currentAudioBytes: result.audioBytes,
      );
      return result;
    } catch (e) {
      state = state.copyWith(isGenerating: false);
      rethrow;
    }
  }

  Future<String?> saveAudio() async {
    final bytes = state.currentAudioBytes;
    if (bytes == null) return null;
    return await _audioService.saveToFile(bytes);
  }

  Future<bool> startServer() async {
    try {
      await _server.start(
        port: _storage.serverPort,
        apiKey: _storage.apiKey,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  void stopServer() {
    _server.stop();
  }

  bool get serverRunning => _server.isRunning;
}

final homeStateProvider =
    StateNotifierProvider<HomeStateNotifier, HomeState>((ref) {
  return HomeStateNotifier(
    ref.watch(ttsServiceProvider),
    ref.watch(audioServiceProvider),
    ref.watch(storageProvider),
    ref.watch(serverServiceProvider),
  );
});
