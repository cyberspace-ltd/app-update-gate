/// A lightweight semantic version parser and comparator.
///
/// Supports the standard `major.minor.patch` format. Pre-release and build
/// metadata suffixes are stripped before comparison so that `1.2.3-beta`
/// compares as `1.2.3`.
class SemanticVersion implements Comparable<SemanticVersion> {
  /// Major version number.
  final int major;

  /// Minor version number.
  final int minor;

  /// Patch version number.
  final int patch;

  /// Creates a [SemanticVersion] from explicit components.
  const SemanticVersion(this.major, this.minor, this.patch);

  /// Parses a version string like `"2.4.1"` or `"1.0.0-beta+3"`.
  ///
  /// Throws [FormatException] if the string cannot be parsed into at least
  /// a major version number.
  factory SemanticVersion.parse(String versionString) {
    var cleaned = versionString.trim();
    if (cleaned.startsWith('v') || cleaned.startsWith('V')) {
      cleaned = cleaned.substring(1);
    }

    final coreEnd = cleaned.indexOf(RegExp(r'[-+]'));
    if (coreEnd != -1) {
      cleaned = cleaned.substring(0, coreEnd);
    }

    final parts = cleaned.split('.');
    if (parts.isEmpty || parts.length > 3) {
      throw FormatException(
        'Invalid semantic version: "$versionString"',
      );
    }

    int parsePart(int index) {
      if (index >= parts.length) return 0;
      final value = int.tryParse(parts[index]);
      if (value == null || value < 0) {
        throw FormatException(
          'Invalid version component "${parts[index]}" in "$versionString"',
        );
      }
      return value;
    }

    return SemanticVersion(parsePart(0), parsePart(1), parsePart(2));
  }

  bool operator >(SemanticVersion other) => compareTo(other) > 0;
  bool operator >=(SemanticVersion other) => compareTo(other) >= 0;
  bool operator <(SemanticVersion other) => compareTo(other) < 0;
  bool operator <=(SemanticVersion other) => compareTo(other) <= 0;

  @override
  int compareTo(SemanticVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemanticVersion &&
          major == other.major &&
          minor == other.minor &&
          patch == other.patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}
