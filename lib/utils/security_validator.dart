class SecurityValidator {
  /// Enforces password policy:
  /// - At least 12 characters
  /// - At least one uppercase letter (A-Z)
  /// - At least one lowercase letter (a-z)
  /// - At least one digit (0-9)
  /// - At least one special symbol (!@#$%^&*...)
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required.';
    }

    if (password.length < 12) {
      return 'Password must be at least 12 characters long.';
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter.';
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain at least one lowercase letter.';
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least one number.';
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-=+~/\\\[\]]').hasMatch(password)) {
      return 'Password must contain at least one special character.';
    }

    // Common weak password patterns
    final lower = password.toLowerCase();
    if (lower.contains('password') || lower.contains('123456') || lower.contains('qwerty')) {
      return 'Password contains an easily guessable pattern.';
    }

    return null; // Valid password
  }
}