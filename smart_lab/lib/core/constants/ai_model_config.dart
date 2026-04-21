class AiModelOption {
  final String id;
  final String provider;
  final String purpose;
  final bool primary;

  const AiModelOption({
    required this.id,
    required this.provider,
    required this.purpose,
    this.primary = false,
  });
}

class AiModelConfig {
  AiModelConfig._();

  static const AiModelOption primaryVisionModel = AiModelOption(
    id: 'Qwen/Qwen3-VL-32B-Instruct',
    provider: 'SiliconFlow',
    purpose: 'Primary image safety inspection model',
    primary: true,
  );

  static const AiModelOption backupVisionModel = AiModelOption(
    id: 'zai-org/GLM-4.6V',
    provider: 'SiliconFlow',
    purpose: 'Backup model for complex scenes',
  );

  static const AiModelOption compatibilityVisionModel = AiModelOption(
    id: 'Qwen/Qwen2.5-VL-32B-Instruct',
    provider: 'SiliconFlow',
    purpose: 'Compatibility fallback model',
  );

  static const List<AiModelOption> inspectionModels = [
    primaryVisionModel,
    backupVisionModel,
    compatibilityVisionModel,
  ];
}
