import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mimo_tts_service.dart';
import '../providers/home_state_provider.dart';

class BuiltInVoiceTab extends ConsumerWidget {
  final TextEditingController textController;
  final TextEditingController styleController;
  final VoidCallback onGenerate;

  const BuiltInVoiceTab({
    super.key,
    required this.textController,
    required this.styleController,
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
          const Text('选择音色', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MimoTtsService.builtInVoices.map((v) {
              final id = v['id']!;
              final name = v['name']!;
              final lang = v['lang']!;
              final gender = v['gender']!;
              final selected = homeState.selectedVoice == id;
              return ChoiceChip(
                label: Text('$name ($lang $gender)'),
                selected: selected,
                onSelected: (_) =>
                    ref.read(homeStateProvider.notifier).updateVoice(id),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('风格指令（可选）', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: styleController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: '例如：用温柔欢快的语气，语速稍快',
              border: OutlineInputBorder(),
              helperText: '自然语言描述期望的语音风格，或使用音频标签如 (温柔地)',
            ),
          ),
          const SizedBox(height: 16),
          const Text('合成文本', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: textController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: '请输入要合成语音的文本...',
              border: OutlineInputBorder(),
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
