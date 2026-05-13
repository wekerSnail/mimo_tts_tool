import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/home_state_provider.dart';

class VoiceDesignTab extends ConsumerWidget {
  final TextEditingController textController;
  final TextEditingController voiceDescController;
  final VoidCallback onGenerate;

  const VoiceDesignTab({
    super.key,
    required this.textController,
    required this.voiceDescController,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeStateProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('音色描述', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: voiceDescController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: '例如：年轻女性，温柔甜美的声音，语速适中',
              border: OutlineInputBorder(),
              helperText: '描述期望的音色特征，支持中英文',
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            title: const Text('智能润色文本'),
            subtitle: const Text('开启后可省略合成文本，由AI自动润色'),
            value: homeState.optimizeTextPreview,
            onChanged: (v) => ref
                .read(homeStateProvider.notifier)
                .updateOptimizeTextPreview(v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          const Text('合成文本', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: textController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: homeState.optimizeTextPreview
                  ? '可留空，由AI自动生成文本'
                  : '请输入要合成语音的文本...',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: homeState.isGenerating ? null : onGenerate,
              icon: homeState.isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(homeState.isGenerating ? '生成中...' : '生成语音'),
            ),
          ),
        ],
      ),
    );
  }
}
