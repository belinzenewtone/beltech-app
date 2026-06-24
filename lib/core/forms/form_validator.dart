import 'package:flutter/material.dart';
import 'package:beltech/core/forms/form_schema.dart';

FormFieldValidator<String> formFieldValidator(FieldRule rule) {
  return (value) {
    final schema = FormSchema(fields: [rule]);
    final result = schema.validate({rule.fieldName: value});
    return result.errors[rule.fieldName];
  };
}

ValidationResult validateForm(FormSchema schema, Map<String, String?> values) {
  return schema.validate(values);
}
