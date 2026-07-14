# Review Feature

## Purpose
Provides weekly review insights combining transactions, budgets, and task completion trends.

## Main Components
- `domain/entities/week_review_data.dart`:
  - Domain models for weekly metrics and chart payloads.
- `presentation/providers/review_providers.dart`:
  - Riverpod providers that aggregate review data from repositories.
- `presentation/week_review_screen.dart`:
  - Weekly review dashboard UI and visual summaries.

## Dependencies and Integration
- Pulls data from existing feature repositories (expenses, budget, tasks, income).
- Routed from profile/tooling navigation to provide cross-feature weekly analytics.
