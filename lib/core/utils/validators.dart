class Validators {
  static String? email(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!re.hasMatch(v)) return 'Invalid email';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? required(String? v, [String? field]) {
    if (v == null || v.trim().isEmpty) {
      return '${field ?? 'This field'} is required';
    }
    return null;
  }
}