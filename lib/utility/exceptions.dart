class NoValidTokenException implements Exception {
  final String message;

  NoValidTokenException(this.message);
}
