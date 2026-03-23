
/// Reads app version info at runtime.
class AppInfo {
  static String _version = '1.0.0';
  static String _buildNumber = '1';

  /// Initialize by reading from platform.
  static Future<void> initialize() async {
    // In a real app, use package_info_plus to read from pubspec.
    // For now, set from the pubspec values.
    _version = '1.0.0';
    _buildNumber = '1';
  }

  static String get version => _version;
  static String get buildNumber => _buildNumber;
  static String get fullVersion => '$_version+$_buildNumber';
}
