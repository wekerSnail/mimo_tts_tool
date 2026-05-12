import 'dart:convert';
import 'package:http/http.dart' as http;

class TtsResult {
  final List<int> audioBytes;
  final String format;

  TtsResult({required this.audioBytes, required this.format});
}

class MimoTtsService {
  static const _baseUrl = 'https://api.xiaomimimo.com/v1/chat/completions';

  static const builtInVoices = <Map<String, String>>[
    {'id': '冰糖', 'name': '冰糖', 'lang': '中文', 'gender': '女'},
    {'id': '茉莉', 'name': '茉莉', 'lang': '中文', 'gender': '女'},
    {'id': '苏打', 'name': '苏打', 'lang': '中文', 'gender': '男'},
    {'id': '白桦', 'name': '白桦', 'lang': '中文', 'gender': '男'},
    {'id': 'Mia', 'name': 'Mia', 'lang': 'English', 'gender': 'Female'},
    {'id': 'Chloe', 'name': 'Chloe', 'lang': 'English', 'gender': 'Female'},
    {'id': 'Milo', 'name': 'Milo', 'lang': 'English', 'gender': 'Male'},
    {'id': 'Dean', 'name': 'Dean', 'lang': 'English', 'gender': 'Male'},
  ];

  Future<TtsResult> synthesize({
    required String apiKey,
    required String model,
    required String text,
    String? styleInstruction,
    String? voice,
    String format = 'wav',
    String? voiceCloneBase64,
    bool optimizeTextPreview = false,
  }) async {
    final messages = <Map<String, String>>[];

    if (model == 'mimo-v2.5-tts') {
      if (styleInstruction != null && styleInstruction.isNotEmpty) {
        messages.add({'role': 'user', 'content': styleInstruction});
      }
      messages.add({'role': 'assistant', 'content': text});
    } else if (model == 'mimo-v2.5-tts-voicedesign') {
      messages.add({'role': 'user', 'content': styleInstruction ?? ''});
      messages.add({'role': 'assistant', 'content': text});
    } else if (model == 'mimo-v2.5-tts-voiceclone') {
      if (styleInstruction != null && styleInstruction.isNotEmpty) {
        messages.add({'role': 'user', 'content': styleInstruction});
      } else {
        messages.add({'role': 'user', 'content': ''});
      }
      messages.add({'role': 'assistant', 'content': text});
    }

    final audio = <String, dynamic>{'format': format};

    if (model == 'mimo-v2.5-tts') {
      audio['voice'] = voice ?? '冰糖';
    } else if (model == 'mimo-v2.5-tts-voicedesign') {
      // voicedesign 不需要额外的 audio 字段
    } else if (model == 'mimo-v2.5-tts-voiceclone') {
      audio['voice'] = voiceCloneBase64 ?? '';
    }

    final body = jsonEncode({
      'model': model,
      'messages': messages,
      'audio': audio,
    });

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'api-key': apiKey,
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      String errorMsg;
      try {
        final err = jsonDecode(response.body);
        errorMsg = err['error']?['message'] ?? response.body;
      } catch (_) {
        errorMsg = response.body;
      }
      throw Exception('API Error (${response.statusCode}): $errorMsg');
    }

    final json = jsonDecode(response.body);
    final audioData = json['choices'][0]['message']['audio']['data'] as String;
    final audioBytes = base64Decode(audioData);

    return TtsResult(audioBytes: audioBytes, format: format);
  }
}
