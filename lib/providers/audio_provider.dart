import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audio_service.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  ref.keepAlive();
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});

class AudioStateNotifier extends Notifier<AudioState> {
  StreamSubscription<AudioState>? _sub;

  @override
  AudioState build() {
    final service = ref.watch(audioServiceProvider);
    _sub = service.stateStream.listen((s) {
      state = s;
    });
    ref.onDispose(() => _sub?.cancel());
    return service.currentState;
  }
}

final audioStateProvider =
    NotifierProvider<AudioStateNotifier, AudioState>(AudioStateNotifier.new);
