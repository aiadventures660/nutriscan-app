library api_config;

import 'dart:convert';

/// Google AI Studio Free-Tier API Configuration & Model Registry
/// Base URL: https://generativelanguage.googleapis.com/v1beta
/// Key Portal: https://aistudio.google.com/app/apikey (Free tier, no credit card required)

class GeminiModelInfo {
  final String id;
  final String apiModelId;
  final String displayName;
  final String contextWindow;
  final String maxOutput;
  final String modality;
  final bool isFreeTier;
  final String badgeText;
  final String description;

  const GeminiModelInfo({
    required this.id,
    required this.apiModelId,
    required this.displayName,
    required this.contextWindow,
    required this.maxOutput,
    required this.modality,
    this.isFreeTier = true,
    required this.badgeText,
    required this.description,
  });
}

class ApiConfig {
  // Base endpoint for Google Generative Language API
  static const String baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String freeTierKeyUrl = 'https://aistudio.google.com/app/apikey';

  // Environment-injected API key (--dart-define=GEMINI_API_KEY=...)
  static const String _envApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  /// Resolves the API key supplied at build time or runtime.
  static String get defaultApiKey {
    return _envApiKey.trim();
  }

  // User-configurable runtime key and active model
  static String? customApiKey;
  static String activeModel = 'gemini-flash-lite-latest';

  // Clerk Authentication Configuration
  static const String clerkPublishableKey = String.fromEnvironment(
    'CLERK_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_YnVyc3Rpbmctc3RvcmstODM5Mi5jbGVyay5hY2NvdW50cy5kZXYk',
  );
  static const String clerkApplicationId = 'app_3MFQeKduTlDlvScWQinKnELN9cx';

  // Production Render URL default
  static const String productionBackendUrl = 'https://nutriscan-backend-3sl6.onrender.com/api/v1';

  // Backend API Configuration (Node + Express + Supabase + Clerk)
  // Connects directly to deployed live Render HTTPS backend by default.
  static const String defaultBackendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: productionBackendUrl,
  );
  static String backendBaseUrl = defaultBackendUrl;

  /// Update backend API URL dynamically at runtime
  static void setBackendUrl(String url) {
    if (url.trim().isNotEmpty) {
      backendBaseUrl = url.trim();
    }
  }

  // Effective API key
  static String get effectiveApiKey {
    if (customApiKey != null && customApiKey!.trim().isNotEmpty) {
      return customApiKey!.trim();
    }
    return defaultApiKey;
  }

  // Backward-compatible alias for existing callers
  static String get googleAiApiKey => effectiveApiKey;
  static String get geminiModel => activeModel;

  // Active verified working Google Gemini models (inactive 2.5, 2.0, 1.5 & gemma removed)
  static const List<GeminiModelInfo> freeTierModels = [
    GeminiModelInfo(
      id: 'gemini-flash-lite-latest',
      apiModelId: 'gemini-flash-lite-latest',
      displayName: 'Gemini Flash-Lite',
      contextWindow: '1M',
      maxOutput: '65K',
      modality: 'Text + Image + Audio + Video',
      badgeText: 'Ultra-Fast Vision',
      description: 'Ultra-rapid multimodal inference optimized for sub-second food recognition.',
    ),
    GeminiModelInfo(
      id: 'gemini-3.5-flash-lite',
      apiModelId: 'gemini-3.5-flash-lite',
      displayName: 'Gemini 3.5 Flash-Lite',
      contextWindow: '1M',
      maxOutput: '65K',
      modality: 'Text + Image + Audio + Video',
      badgeText: 'Ultra-Low Latency',
      description: 'High efficiency multimodal model recommended by Google for fast interactive food coaching.',
    ),
    GeminiModelInfo(
      id: 'gemini-3.1-flash-lite',
      apiModelId: 'gemini-3.1-flash-lite',
      displayName: 'Gemini 3.1 Flash-Lite',
      contextWindow: '1M',
      maxOutput: '65K',
      modality: 'Text + Image + Audio + Video',
      badgeText: 'Lightweight & Rapid',
      description: 'Compact high-efficiency multimodal model with full 1M context support.',
    ),
    GeminiModelInfo(
      id: 'gemini-3.8-flash',
      apiModelId: 'gemini-3.8-flash',
      displayName: 'Gemini 3.8 Flash',
      contextWindow: '1M',
      maxOutput: '65K',
      modality: 'Text + Image + Audio + Video',
      badgeText: 'Flagship Speed',
      description: 'Next-gen flagship multimodal reasoning with ultra-fast inference and 1M context window.',
    ),
    GeminiModelInfo(
      id: 'gemini-3.6-flash',
      apiModelId: 'gemini-3.6-flash',
      displayName: 'Gemini 3.6 Flash',
      contextWindow: '1M',
      maxOutput: '65K',
      modality: 'Text + Image + Audio + Video',
      badgeText: 'High Performance',
      description: 'Advanced food vision, macro calculation, NOVA processing, and food additive analysis.',
    ),
    GeminiModelInfo(
      id: 'gemini-flash-latest',
      apiModelId: 'gemini-flash-latest',
      displayName: 'Gemini Flash',
      contextWindow: '1M',
      maxOutput: '65K',
      modality: 'Text + Image + Audio + Video',
      badgeText: 'Stable Release',
      description: 'Google production multimodal flash model alias.',
    ),
  ];

  static const int maxImageSize = 4 * 1024 * 1024; // 4MB max
  static const Duration requestTimeout = Duration(seconds: 10);

  /// Find model metadata by ID with safe fallback to active model
  static GeminiModelInfo getModelInfo(String modelId) {
    return freeTierModels.firstWhere(
      (m) => m.id == modelId || m.apiModelId == modelId,
      orElse: () => freeTierModels.first,
    );
  }

  /// Construct an intelligent multi-model fallback chain placing the primary model first
  static List<String> getFallbackChain(String primaryModelId) {
    final primary = getModelInfo(primaryModelId);
    final chain = <String>[primary.apiModelId];

    // Add other active models in order of verified response speed
    for (final model in freeTierModels) {
      if (!chain.contains(model.apiModelId)) {
        chain.add(model.apiModelId);
      }
    }

    return chain;
  }

  // Dynamic backward-compatible fallback list
  static List<String> get fallbackModels => getFallbackChain(activeModel);

  // Validation
  static bool get isApiKeyConfigured =>
      effectiveApiKey.isNotEmpty &&
      effectiveApiKey != 'YOUR_GOOGLE_AI_API_KEY_HERE';

  /// Mask API Key for secure UI presentation (e.g., '••••••••••••66nQ')
  static String maskKey(String? key) {
    if (key == null || key.trim().isEmpty) return 'Default Key Active';
    final trimmed = key.trim();
    if (trimmed.length <= 8) return '••••••••';
    final suffix = trimmed.substring(trimmed.length - 4);
    return '••••••••••••$suffix';
  }

  /// Strips and redacts any API keys from URLs, stack traces, and logs
  static String sanitizeLog(String log) {
    return log
        .replaceAll(RegExp(r'key=[^&\s"''>]+', caseSensitive: false), 'key=[REDACTED]')
        .replaceAll(RegExp(r'AQ\.[A-Za-z0-9_-]{20,}'), '[REDACTED_KEY]')
        .replaceAll(RegExp(r'AIzaSy[A-Za-z0-9_-]{20,}'), '[REDACTED_KEY]');
  }

  /// Obfuscate key before writing to SharedPreferences
  static String encodeKey(String raw) {
    if (raw.isEmpty) return '';
    const salt = 0xA5;
    final bytes = utf8.encode(raw);
    final masked = bytes.map((b) => b ^ salt).toList();
    return base64Encode(masked);
  }

  /// Deobfuscate key loaded from SharedPreferences
  static String decodeKey(String encoded) {
    if (encoded.isEmpty) return '';
    try {
      const salt = 0xA5;
      final bytes = base64Decode(encoded);
      final unmasked = bytes.map((b) => b ^ salt).toList();
      return utf8.decode(unmasked);
    } catch (_) {
      return encoded; // Fallback for plain legacy keys
    }
  }
}
