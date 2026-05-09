/// Validation status enum for scientific lexicon entries
/// Matches the validation_status_enum in the SQL schema
enum ValidationStatus {
  pending('pending'),
  validated('validated'),
  rejected('rejected');

  final String value;

  const ValidationStatus(this.value);

  static ValidationStatus fromString(String value) {
    return ValidationStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ValidationStatus.pending,
    );
  }
}
