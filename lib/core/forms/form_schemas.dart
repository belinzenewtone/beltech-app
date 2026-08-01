import 'package:beltech/core/forms/form_schema.dart';

class FormSchemas {
  FormSchemas._();

  static const taskSchema = FormSchema(
    fields: [
      FieldRule(
        fieldName: 'title',
        label: 'Title',
        required: true,
        minLength: 2,
        maxLength: 100,
      ),
      FieldRule(fieldName: 'description', label: 'Description', maxLength: 500),
    ],
  );

  static const expenseSchema = FormSchema(
    fields: [
      FieldRule(
        fieldName: 'title',
        label: 'Title',
        required: true,
        minLength: 2,
        maxLength: 100,
      ),
      FieldRule(
        fieldName: 'amount',
        label: 'Amount',
        required: true,
        isNumeric: true,
        min: 1,
        max: 999999999,
      ),
      FieldRule(fieldName: 'category', label: 'Category', required: true),
    ],
  );

  static const eventSchema = FormSchema(
    fields: [
      FieldRule(
        fieldName: 'title',
        label: 'Title',
        required: true,
        minLength: 2,
        maxLength: 100,
      ),
      FieldRule(fieldName: 'note', label: 'Note', maxLength: 500),
    ],
  );

  static const billSchema = FormSchema(
    fields: [
      FieldRule(
        fieldName: 'name',
        label: 'Name',
        required: true,
        minLength: 2,
        maxLength: 100,
      ),
      FieldRule(
        fieldName: 'amount',
        label: 'Amount',
        required: true,
        isNumeric: true,
        min: 1,
      ),
    ],
  );

  static const loanSchema = FormSchema(
    fields: [
      FieldRule(
        fieldName: 'name',
        label: 'Name',
        required: true,
        minLength: 2,
        maxLength: 100,
      ),
      FieldRule(
        fieldName: 'totalAmount',
        label: 'Total Amount',
        required: true,
        isNumeric: true,
        min: 1,
      ),
      FieldRule(
        fieldName: 'outstandingAmount',
        label: 'Outstanding',
        required: true,
        isNumeric: true,
        min: 0,
      ),
    ],
  );

  static const goalSchema = FormSchema(
    fields: [
      FieldRule(
        fieldName: 'title',
        label: 'Title',
        required: true,
        minLength: 2,
        maxLength: 100,
      ),
      FieldRule(
        fieldName: 'targetAmount',
        label: 'Target Amount',
        required: true,
        isNumeric: true,
        min: 1,
      ),
      FieldRule(
        fieldName: 'currentAmount',
        label: 'Current Amount',
        isNumeric: true,
        min: 0,
      ),
    ],
  );

  static const budgetSchema = FormSchema(
    fields: [
      FieldRule(
        fieldName: 'category',
        label: 'Category',
        required: true,
        minLength: 2,
      ),
      FieldRule(
        fieldName: 'monthlyLimit',
        label: 'Monthly Limit',
        required: true,
        isNumeric: true,
        min: 1,
      ),
    ],
  );

  static const incomeSchema = FormSchema(
    fields: [
      FieldRule(
        fieldName: 'title',
        label: 'Title',
        required: true,
        minLength: 2,
        maxLength: 100,
      ),
      FieldRule(
        fieldName: 'amount',
        label: 'Amount',
        required: true,
        isNumeric: true,
        min: 1,
      ),
      FieldRule(
        fieldName: 'source',
        label: 'Source',
        required: true,
        minLength: 2,
      ),
    ],
  );
}
