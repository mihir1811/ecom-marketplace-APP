/// Gem Agent runtime settings, supplied at build time through
/// `--dart-define-from-file=.env` (see `.env.example`). Nothing is hardcoded.
class GemAgentConfig {
  const GemAgentConfig({
    required this.apiKey,
    required this.model,
    required this.baseUrl,
    this.reasoningEffort = 'none',
  });

  factory GemAgentConfig.fromEnvironment() => const GemAgentConfig(
    apiKey: String.fromEnvironment('OPENAI_API_KEY'),
    model: String.fromEnvironment(
      'GEM_AGENT_MODEL',
      defaultValue: 'gpt-6-luna',
    ),
    baseUrl: String.fromEnvironment(
      'GEM_AGENT_BASE_URL',
      defaultValue: 'https://api.openai.com/v1',
    ),
    reasoningEffort: String.fromEnvironment(
      'GEM_AGENT_REASONING_EFFORT',
      defaultValue: 'none',
    ),
  );

  final String apiKey;
  final String model;

  /// OpenAI-compatible base URL; point at a proxy to keep the key off-device.
  final String baseUrl;

  /// Sent as `reasoning_effort`. Reasoning models only allow function tools
  /// on Chat Completions with `none`; empty omits the field for models that
  /// do not accept it.
  final String reasoningEffort;

  bool get isConfigured => apiKey.isNotEmpty;

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 45);
}
