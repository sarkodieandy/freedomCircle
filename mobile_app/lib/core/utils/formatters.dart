class AppFormatters {
  const AppFormatters._();

  static String compactCount(int value) {
    if (value >= 1000) {
      final result = value / 1000;
      return '${result.toStringAsFixed(result >= 10 ? 0 : 1)}k';
    }
    return value.toString();
  }

  static String percent(double value) => '${(value * 100).round()}%';
}
