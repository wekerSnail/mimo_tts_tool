import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_server_service.dart';

final serverServiceProvider = Provider<LocalServerService>((ref) {
  ref.keepAlive();
  final service = LocalServerService();
  ref.onDispose(() => service.stop());
  return service;
});

final serverRunningProvider = StateProvider<bool>((ref) => false);
