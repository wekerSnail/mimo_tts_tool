import 'package:flutter/material.dart';

class VoiceDesignTab extends StatefulWidget {
  final TextEditingController textController;
  final TextEditingController voiceDescController;
  final bool optimizeTextPreview;
  final ValueChanged<bool> onOptimizeChanged;
  final VoidCallback onGenerate;
  final bool isGenerating;

  const VoiceDesignTab({
    super.key,
    required this.textController,
    required this.voiceDescController,
    required this.optimizeTextPreview,
    required this.onOptimizeChanged,
    required this.onGenerate,
    required this.isGenerating,
  });

  @override
  State<VoiceDesignTab> createState() => _VoiceDesignTabState();
}

class _VoiceDesignTabState extends State<VoiceDesignTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('音色描述', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: widget.voiceDescController,
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
            value: widget.optimizeTextPreview,
            onChanged: (v) => widget.onOptimizeChanged(v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          const Text('合成文本', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: widget.textController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: widget.optimizeTextPreview
                  ? '可留空，由AI自动生成文本'
                  : '请输入要合成语音的文本...',
              border: const OutlineInputBorder(),
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
