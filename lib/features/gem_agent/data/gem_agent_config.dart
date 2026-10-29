/// Gem Agent runtime settings, supplied at build time through
/// `--dart-define-from-file=.env` (see `.env.example`). Nothing is hardcoded.
///
/// Production: set `GEM_AGENT_PROXY_AUTH=true` and point
/// `GEM_AGENT_BASE_URL` at the GemWorld backend's OpenAI-compatible proxy.
/// The app then sends the user's GemWorld session token instead of a
/// provider key, and no model key ships inside the app binary (anything
/// compiled in can be extracted from the APK / IPA).
class GemAgentConfig {
  const GemAgentConfig({
    required this.apiKey,
    required this.model,
    required this.baseUrl,
    this.reasoningEffort = 'none',
    this.enabled = true,
    this.proxyAuth = false,
    this.maxOutputTokens = 700,
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
    enabled: bool.fromEnvironment('GEM_AGENT_ENABLED', defaultValue: true),
    proxyAuth: bool.fromEnvironment('GEM_AGENT_PROXY_AUTH'),
    maxOutputTokens: int.fromEnvironment(
      'GEM_AGENT_MAX_OUTPUT_TOKENS',
      defaultValue: 700,
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

  /// Build-time kill switch. Off hides nothing in the UI but every model
  /// turn answers "unavailable"; local answers keep working.
  final bool enabled;

  /// Authenticate to [baseUrl] with the signed-in user's GemWorld token
  /// (backend proxy) instead of [apiKey].
  final bool proxyAuth;

  /// Upper bound on generated tokens per model call (cost / runaway guard).
  /// Zero omits the field.
  final int maxOutputTokens;

  bool get isConfigured =>
      enabled && (proxyAuth ? baseUrl.isNotEmpty : apiKey.isNotEmpty);

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 45);

  /// Transient failures (429, 5xx, timeouts) are retried this many times.
  static const int retries = 1;
}
