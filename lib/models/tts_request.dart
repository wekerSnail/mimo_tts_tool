class TtsRequest {
  final String model;
  final String text;
  final String? styleInstruction;
  final String? voice;
  final String? voiceCloneBase64;
  final bool optimizeTextPreview;

  const TtsRequest({
    required this.model,
    required this.text,
    this.styleInstruction,
    this.voice,
    this.voiceCloneBase64,
    this.optimizeTextPreview = false,
  });
}
