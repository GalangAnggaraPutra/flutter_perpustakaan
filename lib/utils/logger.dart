class Logger {
  static void error(String message) {
    print('ERROR: $message'); // In production, use proper logging
  }

  static void info(String message) {
    print('INFO: $message');
  }

  static void debug(String message) {
    print('DEBUG: $message');
  }
} 