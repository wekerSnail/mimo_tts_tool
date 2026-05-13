import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mimo_tts_service.dart';

final ttsServiceProvider = Provider<MimoTtsService>((ref) {
  ref.keepAlive();
  return MimoTtsService();
});
