# Insights Feature

## Purpose
Aggregates AI-generated and rule-based financial/life insight cards into a dedicated feed. Provides at-a-glance intelligence about spending patterns, budget adherence, task productivity, anomalies, bills, savings, and financial tips.

## Main Components
- `domain/entities/insight_card.dart`:
  - `InsightCard` entity with kind, tone, confidence, and optional action route.
  - `InsightKind` and `InsightTone` enums for categorisation.
- `presentation/providers/insights_providers.dart`:
  - `insightsProvider` — Riverpod FutureProvider that computes insights from expense, budget, task, income, and bill repositories.
- `presentation/screens/insights_screen.dart`:
  - `InsightsScreen` — ConsumerStatefulWidget rendering a scrollable feed of insight cards inside `SecondaryPageShell`.

## Dependencies and Integration
- Pulls data from feature providers: expenses, budget, tasks, income, and bills.
- Routed at `/insights` via `app_router.dart`.
- Cards optionally navigate to related screens (budget, analytics, tasks, bills, goals) via `actionRoute`.
