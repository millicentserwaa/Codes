class Validators {
  /// Validates a name field.
  /// Allows letters (including accented), spaces, hyphens, apostrophes.
  /// No digits, no special characters like @, #, !, etc.
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 100) {
      return 'Name must be less than 100 characters';
    }
    // Allow letters (including Ghanaian/accented), spaces, hyphens, apostrophes
    // e.g. "Kofi Atta-Mills", "Abena O'Brien", "Kwabená"
    final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ\s'\-]+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Name can only contain letters, hyphens, or apostrophes';
    }
    return null; // valid
  }
}