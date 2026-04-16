class KlingServerException implements Exception {
  final String message;
  final int? statusCode;
  KlingServerException(this.message, {this.statusCode});
  @override
  String toString() => 'KlingServerException: $message (status: $statusCode)';
}
