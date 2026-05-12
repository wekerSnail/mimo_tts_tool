import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'mimo_tts_service.dart';

class LocalServerService {
  HttpServer? _server;
  final MimoTtsService _ttsService = MimoTtsService();

  bool get isRunning => _server != null;
  int? get port => _server?.port;

  Future<void> start({
    required int port,
    required String apiKey,
    String defaultModel = 'mimo-v2.5-tts',
    String defaultVoice = '冰糖',
  }) async {
    if (_server != null) await stop();

    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    _server!.listen((request) async {
      try {
        await _handleRequest(request, apiKey, defaultModel, defaultVoice);
      } catch (e) {
        try {
          request.response
            ..statusCode = HttpStatus.internalServerError
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'error': {'message': e.toString()}}));
          await request.response.close();
        } catch (_) {}
      }
    });
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> _handleRequest(
    HttpRequest request,
    String apiKey,
    String defaultModel,
    String defaultVoice,
  ) async {
    final path = request.uri.path;
    final method = request.method;

    if (method == 'GET' && path == '/health') {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'status': 'ok',
          'server': 'MiMo TTS Local Server',
          'default_model': defaultModel,
        }));
      await request.response.close();
      return;
    }

    if (method == 'GET' && path == '/v1/audio/voices') {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'voices': MimoTtsService.builtInVoices,
        }));
      await request.response.close();
      return;
    }

    if (method == 'POST' && path == '/v1/audio/speech') {
      final body = await utf8.decoder.bind(request).join();
      Map<String, dynamic> params;
      try {
        params = jsonDecode(body) as Map<String, dynamic>;
      } catch (e) {
        request.response
          ..statusCode = HttpStatus.badRequest
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'error': {'message': 'Invalid JSON body'}}));
        await request.response.close();
        return;
      }

      final input = params['input'] as String?;
      if (input == null || input.isEmpty) {
        request.response
          ..statusCode = HttpStatus.badRequest
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'error': {'message': '"input" is required'}}));
        await request.response.close();
        return;
      }

      final model = params['model'] as String? ?? defaultModel;
      final voice = params['voice'] as String? ?? defaultVoice;
      final style = params['style'] as String?;

      final result = await _ttsService.synthesize(
        apiKey: apiKey,
        model: model,
        text: input,
        styleInstruction: style,
        voice: voice,
        format: 'wav',
      );

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType('audio', 'wav')
        ..headers.add('Content-Disposition', 'inline; filename="speech.wav"')
        ..add(result.audioBytes);
      await request.response.close();
      return;
    }

    request.response
      ..statusCode = HttpStatus.notFound
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'error': {'message': 'Not found'}}));
    await request.response.close();
  }
}
