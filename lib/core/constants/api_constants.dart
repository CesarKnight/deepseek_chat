/// Constants used for API configuration
class ApiConstants {
  // API endpoints
  static const String API_URL = 'localhost:8000';

  // API keys
  static const String OPENROUTER_API_KEY = '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';

  // API models
  static const String OPENROUTER_MODEL = 'deepseek/deepseek-r1-distill-qwen-32b:free';

  // Timeout durations (in seconds)
  static const int REQUEST_TIMEOUT = 60;

  // Retry configuration
  static const int MAX_RETRY_ATTEMPTS = 3;
  static const int RETRY_DELAY_SECONDS = 2;
}