/// The emotional tone used for the widget's subtle accent treatment.
enum Mood {
  sunny,
  okay,
  heavy,
  overwhelmed;

  /// Stable value shared with Android widget preferences.
  String get key => name;
}
