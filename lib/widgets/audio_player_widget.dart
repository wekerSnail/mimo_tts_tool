import 'package:flutter/material.dart';
import '../services/audio_service.dart';

class AudioPlayerWidget extends StatelessWidget {
  final AudioService audioService;
  final List<int>? currentAudioBytes;
  final VoidCallback? onSave;

  const AudioPlayerWidget({
    super.key,
    required this.audioService,
    this.currentAudioBytes,
    this.onSave,
  });

  String _formatDuration(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final hasAudio = currentAudioBytes != null && currentAudioBytes!.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.volume_up, size: 20),
                const SizedBox(width: 8),
                const Text('音频播放器', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (hasAudio)
                  Text(
                    '${(currentAudioBytes!.length / 1024).toStringAsFixed(1)} KB',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (!hasAudio)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('暂无音频', style: TextStyle(color: Colors.grey)),
                ),
              )
            else ...[
              Row(
                children: [
                  Text(_formatDuration(audioService.position)),
                  Expanded(
                    child: Slider(
                      value: audioService.duration.inMilliseconds > 0
                          ? audioService.position.inMilliseconds
                              .toDouble()
                              .clamp(0, audioService.duration.inMilliseconds.toDouble())
                          : 0,
                      max: audioService.duration.inMilliseconds > 0
                          ? audioService.duration.inMilliseconds.toDouble()
                          : 1,
                      onChanged: (v) {
                        audioService.seek(Duration(milliseconds: v.toInt()));
                      },
                    ),
                  ),
                  Text(_formatDuration(audioService.duration)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.stop),
                    onPressed: () => audioService.stop(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    iconSize: 48,
                    icon: Icon(
                      audioService.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                    ),
                    onPressed: () {
                      if (audioService.isPlaying) {
                        audioService.pause();
                      } else if (audioService.position > Duration.zero) {
                        audioService.resume();
                      } else if (hasAudio) {
                        audioService.play(currentAudioBytes!);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  if (onSave != null)
                    IconButton(
                      iconSize: 32,
                      icon: const Icon(Icons.save_alt),
                      tooltip: '保存到文件',
                      onPressed: onSave,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
