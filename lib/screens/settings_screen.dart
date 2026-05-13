import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/storage_provider.dart';
import '../providers/home_state_provider.dart';
import '../providers/server_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _portController;
  late bool _serverEnabled;
  late int _port;

  @override
  void initState() {
    super.initState();
    final storage = ref.read(storageProvider);
    _serverEnabled = storage.serverEnabled;
    _port = storage.serverPort;
    _portController = TextEditingController(text: _port.toString());
  }

  @override
  void dispose() {
    _portController.dispose();
    super.dispose();
  }

  void _savePort() {
    final storage = ref.read(storageProvider);
    final p = int.tryParse(_portController.text);
    if (p != null && p > 0 && p <= 65535) {
      storage.serverPort = p;
      _port = p;
    } else {
      _portController.text = _port.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageProvider);

    final serverApiDoc = '''POST http://localhost:$_port/v1/audio/speech

请求参数 (JSON):
{
  "input": "要合成的文本",       // 必填
  "voice": "冰糖",              // 可选，音色ID
  "model": "mimo-v2.5-tts",    // 可选，默认模型
  "style": "(温柔地)",          // 可选，风格指令
  "response_format": "wav"      // 可选，默认 wav
}

响应: 200 OK, Content-Type: audio/wav, 返回 WAV 音频字节''';

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('API 配置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('API Key: '),
                      Expanded(
                        child: Text(
                          storage.apiKey.isNotEmpty
                              ? '${storage.apiKey.substring(0, 8)}...'
                              : '未配置',
                          style: TextStyle(
                            color: storage.apiKey.isNotEmpty ? null : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('本地 TTS 服务', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('启用本地服务'),
                    subtitle: Text(_serverEnabled ? '开启后其他应用可调用此服务生成语音' : '关闭状态'),
                    value: _serverEnabled,
                    onChanged: (v) {
                      setState(() => _serverEnabled = v);
                      storage.serverEnabled = v;
                      final notifier = ref.read(homeStateProvider.notifier);
                      if (v) {
                        notifier.startServer().then((ok) {
                          ref.read(serverRunningProvider.notifier).state = ok;
                        });
                      } else {
                        notifier.stopServer();
                        ref.read(serverRunningProvider.notifier).state = false;
                      }
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('端口: '),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _portController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _savePort(),
                          onEditingComplete: () {
                            _savePort();
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('(默认 8899)', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('调用说明', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        tooltip: '复制',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: serverApiDoc));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已复制到剪贴板')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('启动服务后，可使用以下方式调用:'),
                  const SizedBox(height: 12),
                  const Text('curl 示例:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      'curl -X POST http://localhost:$_port/v1/audio/speech \\\n'
                      '  -H "Content-Type: application/json" \\\n'
                      '  -d \'{"input":"你好世界","voice":"冰糖"}\' \\\n'
                      '  --output output.wav',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.greenAccent),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Python 示例:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      'import requests\n\n'
                      'resp = requests.post(\n'
                      '    "http://localhost:$_port/v1/audio/speech",\n'
                      '    json={"input": "你好世界", "voice": "冰糖"}\n'
                      ')\n\n'
                      'with open("output.wav", "wb") as f:\n'
                      '    f.write(resp.content)',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.greenAccent),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('支持的参数:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  _paramRow('input', '要合成的文本', true),
                  _paramRow('voice', '音色ID (冰糖/茉莉/苏打/白桦/Mia/Chloe/Milo/Dean)', false),
                  _paramRow('model', 'mimo-v2.5-tts / voicedesign / voiceclone', false),
                  _paramRow('style', '风格指令或音频标签', false),
                  _paramRow('response_format', 'wav (默认)', false),
                  const SizedBox(height: 12),
                  const Text('其他端点:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  _paramRow('GET /health', '健康检查', false),
                  _paramRow('GET /v1/audio/voices', '获取可用音色列表', false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paramRow(String name, String desc, bool required) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(name, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
          ),
          Expanded(
            child: Text(
              '${required ? "(必填) " : "(可选) "}$desc',
              style: TextStyle(fontSize: 13, color: required ? Colors.red[300] : Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}
