import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _currentFilePath;

  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;
  String? get currentFilePath => _currentFilePath;

  final void Function()? onStateChanged;

  AudioService({this.onStateChanged}) {
    _player.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      onStateChanged?.call();
    });
    _player.onDurationChanged.listen((d) {
      _duration = d;
      onStateChanged?.call();
    });
    _player.onPositionChanged.listen((p) {
      _position = p;
      onStateChanged?.call();
    });
    _player.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _position = Duration.zero;
      _duration = Duration.zero;
      onStateChanged?.call();
    });
  }

  Future<String> saveToTempFile(List<int> bytes, {String format = 'wav'}) async {
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}\\mimo_tts_$timestamp.$format');
    await file.writeAsBytes(bytes);
    _currentFilePath = file.path;
    return file.path;
  }

  Future<void> play(List<int> bytes, {String format = 'wav'}) async {
    await _player.stop();
    final path = await saveToTempFile(bytes, format: format);
    await _player.play(DeviceFileSource(path));
  }

  Future<void> pause() async => await _player.pause();
  Future<void> resume() async => await _player.resume();
  Future<void> stop() async => await _player.stop();

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
  }
}
