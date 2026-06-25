# DART-2.0 Personal Management App

A Flutter personal management application with a dark glassmorphism UI and feature-based clean architecture.

## Product Direction

Core user experiences (based on provided UI references):

- Home dashboard with daily and weekly summaries.
- Calendar with monthly view and day events.
- Expenses tracking with categories and transactions.
- Tasks tracking with completion status.
- AI assistant for spending/tasks/schedule questions.
- Profile and account/security management.

## Engineering Contracts

- [`AGENTS.md`](./AGENTS.md): AI workflow and execution behavior.
- [`CODING_RULES.md`](./CODING_RULES.md): strict architecture, quality, and coding constraints.
- [`EXECUTION_PLAN.md`](./EXECUTION_PLAN.md): phased implementation roadmap.

## Planned Stack

- Flutter (Dart)
- Riverpod (state management)
- Supabase (primary database and sync)
- Drift (local test fallback)
- Flutter Secure Storage (secrets/credentials)

## Required Toolchain

- Flutter `3.41.6` (stable)
- Dart `3.11.4`

For local consistency:

```bash
fvm use
```

CI is pinned to Flutter `3.41.6` and verifies Dart `3.11.4` for every PR/build.

## Supabase Runtime Configuration

Pass Supabase values through `--dart-define` (not hardcoded in source):

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://sjapmklwyibqvatssctw.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<your-key>
```

Database SQL bootstrap: [`supabase/schema.sql`](./supabase/schema.sql)

Optional assistant proxy override:

```bash
--dart-define=ASSISTANT_PROXY_URL=https://<project>.supabase.co/functions/v1/assistant-proxy
```

Optional OTA update fallback via `--dart-define` (when no Supabase update row is set):

```bash
--dart-define=APP_UPDATE_LATEST_VERSION=1.0.2 \
--dart-define=APP_UPDATE_MIN_VERSION=1.0.0 \
--dart-define=APP_UPDATE_FORCE=false \
--dart-define=APP_UPDATE_TITLE="Update BELTECH App" \
--dart-define=APP_UPDATE_MESSAGE="A newer update is available." \
--dart-define=APP_UPDATE_NOTES="Feature improvements||Bug fixes" \
--dart-define=APP_UPDATE_APK_URL=https://example.com/app-release.apk \
--dart-define=APP_UPDATE_WEBSITE_URL=https://example.com/download
```

## Target Project Structure

```text
lib/
  core/
    theme/
    routing/
    utils/
  features/
    home/
      data/
      domain/
      presentation/
    calendar/
      data/
      domain/
      presentation/
    expenses/
      data/
      domain/
      presentation/
    tasks/
      data/
      domain/
      presentation/
    assistant/
      data/
      domain/
      presentation/
    profile/
      data/
      domain/
      presentation/
test/
```

## Notes

- App now supports Supabase email auth and per-user cloud data sync.
- SMS import supports Android inbox read (`READ_SMS`) and paste-based import.
- MPESA auto-sync runs periodically while app is active/resumed and deduplicates by message hash.
- AI assistant network calls use backend proxy endpoint (Supabase Edge Function), not direct client API keys.
- App supports runtime update prompts with release notes, website fallback, and Android APK in-app install flow.
- Keep secrets in `--dart-define`; do not commit keys in source.
