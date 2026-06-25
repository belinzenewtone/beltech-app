# expenses feature

## Purpose
Provides the expenses user experience for the personal management app.

## Main classes
- Presentation: lib/features/expenses/presentation/
- Domain: lib/features/expenses/domain/
- Data: lib/features/expenses/data/
- `MpesaParserService` for parser-v2 classification and confidence routing
- `ExpensesRepository` review/quarantine/replay intelligence contracts
- paybill registry and Fuliza lifecycle support entities for finance intelligence

## Dependencies
Depends on shared lib/core/ theming/navigation utilities and follows contracts defined in domain.
