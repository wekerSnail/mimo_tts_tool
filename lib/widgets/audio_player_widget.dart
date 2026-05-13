import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_provider.dart';
import '../providers/home_state_provider.dart';

class AudioPlayerWidget extends ConsumerWidget {
  final VoidCallback? onSave;

  const AudioPlayerWidget({
    super.key,
    this.onSave,
  });

  String _formatDuration(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(audioStateProvider);
    final audioService = ref.read(audioServiceProvider);
    final currentAudioBytes = ref.watch(homeStateProvider).currentAudioBytes;
    final hasAudio = currentAudioBytes != null && currentAudioBytes.isNotEmpty;

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
                    '${(currentAudioBytes.length / 1024).toStringAsFixed(1)} KB',
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
                  Text(_formatDuration(state.position)),
                  Expanded(
                    child: Slider(
                      value: state.duration.inMilliseconds > 0
                          ? state.position.inMilliseconds
                              .toDouble()
                              .clamp(0, state.duration.inMilliseconds.toDouble())
                          : 0,
                      max: state.duration.inMilliseconds > 0
                          ? state.duration.inMilliseconds.toDouble()
                          : 1,
                      onChanged: (v) {
                        audioService.seek(Duration(milliseconds: v.toInt()));
                      },
                    ),
                  ),
                  Text(_formatDuration(state.duration)),
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
                      state.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                    ),
                    onPressed: () {
                      if (state.isPlaying) {
                        audioService.pause();
                      } else if (state.position > Duration.zero) {
                        audioService.resume();
                      } else if (hasAudio) {
                        audioService.play(currentAudioBytes);
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
