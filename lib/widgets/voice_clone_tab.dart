import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class VoiceCloneTab extends StatefulWidget {
  final TextEditingController textController;
  final TextEditingController styleController;
  final String? cloneAudioPath;
  final String? cloneAudioBase64;
  final ValueChanged<(String?, String?)> onFilePicked;
  final VoidCallback onGenerate;
  final bool isGenerating;

  const VoiceCloneTab({
    super.key,
    required this.textController,
    required this.styleController,
    required this.cloneAudioPath,
    required this.cloneAudioBase64,
    required this.onFilePicked,
    required this.onGenerate,
    required this.isGenerating,
  });

  @override
  State<VoiceCloneTab> createState() => _VoiceCloneTabState();
}

class _VoiceCloneTabState extends State<VoiceCloneTab> {
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final ext = result.files.single.extension?.toLowerCase() ?? 'wav';
      final mime = ext == 'mp3' ? 'audio/mpeg' : 'audio/wav';
      final b64 = base64Encode(bytes);
      final dataUri = 'data:$mime;base64,$b64';
      widget.onFilePicked((file.path, dataUri));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('克隆音频样本', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.cloneAudioPath != null
                        ? widget.cloneAudioPath!.split(Platform.pathSeparator).last
                        : '未选择文件',
                    style: TextStyle(
                      color: widget.cloneAudioPath != null ? null : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: _pickFile,
                child: const Text('选择文件'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '支持 mp3 和 wav 格式，Base64 编码后不超过 10MB',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Text('风格指令（可选）', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: widget.styleController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: '例如：用温柔欢快的语气',
              border: OutlineInputBorder(),
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
