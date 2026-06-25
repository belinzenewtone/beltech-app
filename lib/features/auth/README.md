# auth feature

## Purpose
Provides account authentication (Supabase email/password) and device security state.

## Main classes
- Presentation: `lib/features/auth/presentation/auth_gate.dart`, `lib/features/auth/presentation/providers/`
- Domain: `lib/features/auth/domain/`
- Data: `lib/features/auth/data/`

## Dependencies
Uses Supabase Auth for account sessions and `local_auth` for biometric checks.
