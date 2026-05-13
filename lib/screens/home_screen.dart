import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/home_state_provider.dart';
import '../providers/server_provider.dart';
import '../providers/storage_provider.dart';
import '../widgets/api_key_dialog.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/built_in_voice_tab.dart';
import '../widgets/voice_design_tab.dart';
import '../widgets/voice_clone_tab.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _textController = TextEditingController();
  final _styleController = TextEditingController();
  final _voiceDescController = TextEditingController();

  static const _models = [
    'mimo-v2.5-tts',
    'mimo-v2.5-tts-voicedesign',
    'mimo-v2.5-tts-voiceclone',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    final storage = ref.read(storageProvider);
    if (storage.apiKey.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showApiKeyDialog());
    }
    if (storage.serverEnabled) {
      _startServer();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _styleController.dispose();
    _voiceDescController.dispose();
    super.dispose();
  }

  Future<void> _showApiKeyDialog() async {
    final storage = ref.read(storageProvider);
    final key = await showDialog<String>(
      context: context,
      builder: (_) => ApiKeyDialog(currentKey: storage.apiKey),
    );
    if (key != null && key.isNotEmpty) {
      storage.apiKey = key;
      final notifier = ref.read(homeStateProvider.notifier);
      if (notifier.serverRunning) {
        notifier.stopServer();
        _startServer();
      }
    }
  }

  Future<void> _startServer() async {
    final ok = await ref.read(homeStateProvider.notifier).startServer();
    ref.read(serverRunningProvider.notifier).state = ok;
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('服务启动失败')),
      );
    }
  }

  Future<void> _generate() async {
    final storage = ref.read(storageProvider);
    if (storage.apiKey.isEmpty) {
      await _showApiKeyDialog();
      if (storage.apiKey.isEmpty) return;
    }

    final text = _textController.text.trim();
    final homeState = ref.read(homeStateProvider);
    if (text.isEmpty && !homeState.optimizeTextPreview) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入要合成的文本')),
      );
      return;
    }

    final modelIndex = _tabController.index;
    final model = _models[modelIndex];

    if (model == 'mimo-v2.5-tts-voiceclone' && homeState.cloneAudioBase64 == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择克隆音频文件')),
      );
      return;
    }

    try {
      await ref.read(homeStateProvider.notifier).generate(
            model: model,
            text: text,
            styleInstruction: model == 'mimo-v2.5-tts-voicedesign'
                ? _voiceDescController.text.trim().isEmpty
                    ? null
                    : _voiceDescController.text.trim()
                : _styleController.text.trim().isEmpty
                    ? null
                    : _styleController.text.trim(),
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveAudio() async {
    try {
      final path = await ref.read(homeStateProvider.notifier).saveAudio();
      if (mounted && path != null) {
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
    final homeState = ref.watch(homeStateProvider);
    final serverRunning = ref.watch(serverRunningProvider);
    final server = ref.watch(serverServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MiMo TTS Tool'),
        actions: [
          if (serverRunning && server.port != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Chip(
                avatar: const Icon(Icons.circle, size: 10, color: Colors.green),
                label: Text('localhost:${server.port}', style: const TextStyle(fontSize: 12)),
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
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
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
                  onGenerate: _generate,
                ),
                VoiceDesignTab(
                  textController: _textController,
                  voiceDescController: _voiceDescController,
                  onGenerate: _generate,
                ),
                VoiceCloneTab(
                  textController: _textController,
                  styleController: _styleController,
                  onGenerate: _generate,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AudioPlayerWidget(
              onSave: homeState.currentAudioBytes != null ? _saveAudio : null,
            ),
          ),
        ],
      ),
    );
  }
}
