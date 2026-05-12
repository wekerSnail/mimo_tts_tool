import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/mimo_tts_service.dart';
import '../services/audio_service.dart';
import '../services/local_server_service.dart';
import '../widgets/api_key_dialog.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/built_in_voice_tab.dart';
import '../widgets/voice_design_tab.dart';
import '../widgets/voice_clone_tab.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storage;

  const HomeScreen({super.key, required this.storage});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final MimoTtsService _ttsService;
  late final AudioService _audioService;
  late final LocalServerService _serverService;

  final _textController = TextEditingController();
  final _styleController = TextEditingController();
  final _voiceDescController = TextEditingController();

  String _selectedVoice = '冰糖';
  bool _optimizeTextPreview = false;
  bool _isGenerating = false;
  List<int>? _currentAudioBytes;
  String? _cloneAudioPath;
  String? _cloneAudioBase64;

  static const _models = [
    'mimo-v2.5-tts',
    'mimo-v2.5-tts-voicedesign',
    'mimo-v2.5-tts-voiceclone',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _ttsService = MimoTtsService();
    _audioService = AudioService(onStateChanged: () => setState(() {}));
    _serverService = LocalServerService();

    if (widget.storage.apiKey.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showApiKeyDialog());
    }

    if (widget.storage.serverEnabled) {
      _startServer();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _styleController.dispose();
    _voiceDescController.dispose();
    _audioService.dispose();
    _serverService.stop();
    super.dispose();
  }

  Future<void> _showApiKeyDialog() async {
    final key = await showDialog<String>(
      context: context,
      builder: (_) => ApiKeyDialog(currentKey: widget.storage.apiKey),
    );
    if (key != null && key.isNotEmpty) {
      widget.storage.apiKey = key;
      if (_serverService.isRunning) {
        _stopServer();
        _startServer();
      }
    }
  }

  Future<void> _startServer() async {
    try {
      await _serverService.start(
        port: widget.storage.serverPort,
        apiKey: widget.storage.apiKey,
      );
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('服务启动失败: $e')),
        );
      }
    }
  }

  void _stopServer() {
    _serverService.stop();
    setState(() {});
  }

  void _toggleServer() {
    if (widget.storage.serverEnabled) {
      _startServer();
    } else {
      _stopServer();
    }
  }

  Future<void> _generate() async {
    if (widget.storage.apiKey.isEmpty) {
      await _showApiKeyDialog();
      if (widget.storage.apiKey.isEmpty) return;
    }

    final text = _textController.text.trim();
    if (text.isEmpty && !_optimizeTextPreview) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入要合成的文本')),
      );
      return;
    }

    final modelIndex = _tabController.index;
    final model = _models[modelIndex];

    if (model == 'mimo-v2.5-tts-voiceclone' && _cloneAudioBase64 == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择克隆音频文件')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final result = await _ttsService.synthesize(
        apiKey: widget.storage.apiKey,
        model: model,
        text: text,
        styleInstruction: _styleController.text.trim().isEmpty
            ? null
            : _styleController.text.trim(),
        voice: model == 'mimo-v2.5-tts' ? _selectedVoice : null,
        voiceCloneBase64: _cloneAudioBase64,
        optimizeTextPreview: _optimizeTextPreview,
      );

      setState(() {
        _currentAudioBytes = result.audioBytes;
        _isGenerating = false;
      });

      await _audioService.play(result.audioBytes, format: result.format);
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveAudio() async {
    if (_currentAudioBytes == null) return;
    try {
      final path = await _audioService.saveToFile(_currentAudioBytes!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已保存到: $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MiMo TTS Tool'),
        actions: [
          if (_serverService.isRunning)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Chip(
                avatar: const Icon(Icons.circle, size: 10, color: Colors.green),
                label: Text('localhost:${_serverService.port}', style: const TextStyle(fontSize: 12)),
                visualDensity: VisualDensity.compact,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.vpn_key),
            tooltip: 'API Key',
            onPressed: _showApiKeyDialog,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '设置',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    storage: widget.storage,
                    onServerToggle: _toggleServer,
                  ),
                ),
              );
              setState(() {});
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '内置音色', icon: Icon(Icons.record_voice_over)),
            Tab(text: '音色设计', icon: Icon(Icons.tune)),
            Tab(text: '音色克隆', icon: Icon(Icons.copy)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                BuiltInVoiceTab(
                  textController: _textController,
                  styleController: _styleController,
                  selectedVoice: _selectedVoice,
                  onVoiceChanged: (v) => setState(() => _selectedVoice = v),
                  onGenerate: _generate,
                  isGenerating: _isGenerating,
                ),
                VoiceDesignTab(
                  textController: _textController,
                  voiceDescController: _voiceDescController,
                  optimizeTextPreview: _optimizeTextPreview,
                  onOptimizeChanged: (v) => setState(() => _optimizeTextPreview = v),
                  onGenerate: _generate,
                  isGenerating: _isGenerating,
                ),
                VoiceCloneTab(
                  textController: _textController,
                  styleController: _styleController,
                  cloneAudioPath: _cloneAudioPath,
                  cloneAudioBase64: _cloneAudioBase64,
                  onFilePicked: (data) {
                    setState(() {
                      _cloneAudioPath = data.$1;
                      _cloneAudioBase64 = data.$2;
                    });
                  },
                  onGenerate: _generate,
                  isGenerating: _isGenerating,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AudioPlayerWidget(
              audioService: _audioService,
              currentAudioBytes: _currentAudioBytes,
              onSave: _currentAudioBytes != null ? _saveAudio : null,
            ),
          ),
        ],
      ),
    );
  }
}
