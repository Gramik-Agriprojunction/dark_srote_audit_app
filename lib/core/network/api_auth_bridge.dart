/// Global hook so API clients can trigger logout without importing auth layer.
class ApiAuthBridge {
  ApiAuthBridge._();

  static void Function()? onUnauthorized;

  static void register(void Function() handler) {
    onUnauthorized = handler;
  }

  static void notifyUnauthorized() {
    onUnauthorized?.call();
  }
}
