# calendar feature

## Purpose
Provides the calendar user experience for the personal management app.

## Main classes
- Presentation: lib/features/calendar/presentation/
- Domain: lib/features/calendar/domain/
- Data: lib/features/calendar/data/
- Calendar screen modes: `Month`, `Events`, and `Tasks`
- Providers: `dayEventsProvider`, `monthEventTypesProvider`, and `visibleMonthProvider`
- Month grid markers show both event days and task days
- Events/Tasks panes support pending-focused view with `Show done` toggle

## Dependencies
Depends on shared lib/core/ theming/navigation utilities and follows contracts defined in domain.
