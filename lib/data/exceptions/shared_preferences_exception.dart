
class SharedPreferencesInitException implements Exception {
  final String message;
  SharedPreferencesInitException(this.message);

  @override
  String toString() => 'SharedPreferencesInitException: $message';
}