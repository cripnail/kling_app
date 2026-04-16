class KlingApiException implements Exception {
  final String message;
  final int? statusCode;
  KlingApiException(this.message, {this.statusCode});
  @override
  String toString() => 'KlingApiException: $message (status: $statusCode)';
}
