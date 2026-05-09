enum TestType {
  labelScan('label_scan'),
  dishScan('dish_scan'),
  scientific('scientific');

  final String value;

  const TestType(this.value);

  static TestType fromString(String value) {
    return TestType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TestType.labelScan,
    );
  }
}
