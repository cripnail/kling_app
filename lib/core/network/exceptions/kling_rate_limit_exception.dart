class KlingRateLimitException implements Exception {
  final String message;
  KlingRateLimitException(this.message);
  @override
  String toString() => 'KlingRateLimitException: $message';
}
