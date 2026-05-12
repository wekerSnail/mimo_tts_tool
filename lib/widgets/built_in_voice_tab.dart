import 'package:flutter/material.dart';
import '../services/mimo_tts_service.dart';

class BuiltInVoiceTab extends StatefulWidget {
  final TextEditingController textController;
  final TextEditingController styleController;
  final String selectedVoice;
  final ValueChanged<String> onVoiceChanged;
  final VoidCallback onGenerate;
  final bool isGenerating;

  const BuiltInVoiceTab({
    super.key,
    required this.textController,
    required this.styleController,
    required this.selectedVoice,
    required this.onVoiceChanged,
    required this.onGenerate,
    required this.isGenerating,
  });

  @override
  State<BuiltInVoiceTab> createState() => _BuiltInVoiceTabState();
}

class _BuiltInVoiceTabState extends State<BuiltInVoiceTab> {
  @override
  Widget build(BuildContext context) {
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
              final selected = widget.selectedVoice == id;
              return ChoiceChip(
                label: Text('$name ($lang $gender)'),
                selected: selected,
                onSelected: (_) => widget.onVoiceChanged(id),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('风格指令（可选）', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: widget.styleController,
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
            controller: widget.textController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: '请输入要合成语音的文本...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: widget.isGenerating ? null : widget.onGenerate,
              icon: widget.isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(widget.isGenerating ? '生成中...' : '生成语音'),
            ),
          ),
        ],
      ),
    );
  }
}
