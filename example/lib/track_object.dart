abstract class HasCreation {
  bool locInfo;

  @override
  String toString() {
    return 'current loc info is $locInfo';
  }
}

/// A tuple with file, line, and column number, for displaying human-readable
/// file locations.
class LocInfo {
  const LocInfo({
    this.file,
    this.line,
    this.column,
    this.name,
    this.parameterLocations,
  });

  /// File path of the location.
  final String file;

  /// 1-based line number.
  final int line;
  /// 1-based column number.
  final int column;

  /// Optional name of the parameter or function at this location.
  final String name;

  /// Optional locations of the parameters of the member at this location.
  final List<LocInfo> parameterLocations;

  Map<String, Object> toJsonMap() {
    final Map<String, Object> json = <String, Object>{
      'file': file,
      'line': line,
      'column': column,
    };
    if (name != null) {
      json['name'] = name;
    }
    if (parameterLocations != null) {
      json['parameterLocations'] = parameterLocations.map<Map<String, Object>>(
              (LocInfo location) => location.toJsonMap()).toList();
    }
    return json;
  }

  @override
  String toString() {
    final List<String> parts = <String>[];
    if (name != null) {
      parts.add(name);
    }
    if (file != null) {
      parts.add(file);
    }
    parts..add('$line')..add('$column');
    return parts.join(':');
  }
}