# update

App update checking and install prompt.

Sources:
- Supabase `app_updates` table (preferred)
- `APP_UPDATE_*` Dart define fallback

Android:
- Shorebird-compatible behavior: shows update guidance and does not run APK in-app installer.

Other platforms:
- Falls back to opening update website URL.
