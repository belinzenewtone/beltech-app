class FieldRule {
  final String fieldName;
  final String? label;
  final bool required;
  final int? minLength;
  final int? maxLength;
  final bool isEmail;
  final bool isNumeric;
  final double? min;
  final double? max;
  final String? Function(String? value)? customValidator;

  const FieldRule({
    required this.fieldName,
    this.label,
    this.required = false,
    this.minLength,
    this.maxLength,
    this.isEmail = false,
    this.isNumeric = false,
    this.min,
    this.max,
    this.customValidator,
  });
}

class ValidationResult {
  final bool isValid;
  final Map<String, String> errors;

  const ValidationResult({required this.isValid, required this.errors});

  factory ValidationResult.valid() =>
      const ValidationResult(isValid: true, errors: {});
}

class FormSchema {
  final List<FieldRule> fields;

  const FormSchema({required this.fields});

  ValidationResult validate(Map<String, String?> values) {
    final errors = <String, String>{};

    for (final field in fields) {
      final value = values[field.fieldName];
      final label = field.label ?? field.fieldName;

      if (field.required && (value == null || value.trim().isEmpty)) {
        errors[field.fieldName] = '$label is required';
        continue;
      }

      if (value == null || value.trim().isEmpty) continue;

      if (field.minLength != null && value.trim().length < field.minLength!) {
        errors[field.fieldName] =
            '$label must be at least ${field.minLength} characters';
      }

      if (field.maxLength != null && value.trim().length > field.maxLength!) {
        errors[field.fieldName] =
            '$label must be at most ${field.maxLength} characters';
      }

      if (field.isEmail &&
          !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
        errors[field.fieldName] = 'Please enter a valid email address';
      }

      if (field.isNumeric) {
        final num = double.tryParse(value.trim());
        if (num == null) {
          errors[field.fieldName] = '$label must be a number';
        } else {
          if (field.min != null && num < field.min!) {
            errors[field.fieldName] = '$label must be at least ${field.min}';
          }
          if (field.max != null && num > field.max!) {
            errors[field.fieldName] = '$label must be at most ${field.max}';
          }
        }
      }

      if (field.customValidator != null) {
        final customError = field.customValidator!(value);
        if (customError != null) {
          errors[field.fieldName] = customError;
        }
      }
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }
}
