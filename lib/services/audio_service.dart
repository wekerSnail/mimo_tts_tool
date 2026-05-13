import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class AudioState {
  final bool isPlaying;
  final Duration duration;
  final Duration position;
  final List<int>? currentBytes;
  final String? currentFilePath;

  const AudioState({
    this.isPlaying = false,
    this.duration = Duration.zero,
    this.position = Duration.zero,
    this.currentBytes,
    this.currentFilePath,
  });

  AudioState copyWith({
    bool? isPlaying,
    Duration? duration,
    Duration? position,
    List<int>? currentBytes,
    String? currentFilePath,
  }) {
    return AudioState(
      isPlaying: isPlaying ?? this.isPlaying,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      currentBytes: currentBytes ?? this.currentBytes,
      currentFilePath: currentFilePath ?? this.currentFilePath,
    );
  }
}

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  final _stateController = StreamController<AudioState>.broadcast();
  AudioState _currentState = const AudioState();

  Stream<AudioState> get stateStream => _stateController.stream;
  AudioState get currentState => _currentState;

  AudioService() {
    _player.onPlayerStateChanged.listen((state) {
      _updateState(isPlaying: state == PlayerState.playing);
    });
    _player.onDurationChanged.listen((d) {
      _updateState(duration: d);
    });
    _player.onPositionChanged.listen((p) {
      _updateState(position: p);
    });
    _player.onPlayerComplete.listen((_) {
      _updateState(
        isPlaying: false,
        position: Duration.zero,
        duration: Duration.zero,
      );
    });
  }

  void _updateState({
    bool? isPlaying,
    Duration? duration,
    Duration? position,
    List<int>? currentBytes,
    String? currentFilePath,
  }) {
    _currentState = _currentState.copyWith(
      isPlaying: isPlaying,
      duration: duration,
      position: position,
      currentBytes: currentBytes,
      currentFilePath: currentFilePath,
    );
    _stateController.add(_currentState);
  }

  Future<String> saveToTempFile(List<int> bytes, {String format = 'wav'}) async {
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}\\mimo_tts_$timestamp.$format');
    await file.writeAsBytes(bytes);
    _updateState(currentFilePath: file.path);
    return file.path;
  }

  Future<void> play(List<int> bytes, {String format = 'wav'}) async {
    await _player.stop();
    final path = await saveToTempFile(bytes, format: format);
    _updateState(currentBytes: bytes);
    await _player.play(DeviceFileSource(path));
  }

  Future<void> pause() async => await _player.pause();
  Future<void> resume() async => await _player.resume();
  Future<void> stop() async {
    await _player.stop();
    _updateState(isPlaying: false, position: Duration.zero);
  }

  Future<void> seek(Duration position) async =>
      await _player.seek(position);

  Future<String?> saveToFile(List<int> bytes, {String format = 'wav'}) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final saveDir = Directory('${docsDir.path}\\MiMoTTS');
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final file = File('${saveDir.path}\\tts_$timestamp.$format');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  void dispose() {
    _player.dispose();
    _stateController.close();
  }
}
