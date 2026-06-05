# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

iOS SwiftUI app for tracking Diablo II: Resurrected boss runs — logging run type, duration (seconds), Magic Find %, and notable drops per run, grouped into sessions.

## Build & Run

Open `D2R Tracker.xcodeproj` in Xcode and run on a simulator or device (iOS 17+ required for SwiftData). There are no tests, no SPM packages, and no external dependencies.

## Architecture

The app has three tabs driven by a single SwiftData model container at the root (`D2R_TrackerApp.swift`):

- **Runs tab** (`ContentView.swift`) — list of sessions with sort controls; tapping a session pushes `SessionDetailView` (runs within that session), which in turn pushes `EditRunView`. A `+` button opens `AddRunView` as a sheet.
- **Stats tab** (`StatsView.swift`) — aggregate stats (total runs, avg MF, avg/total time, most-farmed run type, bar chart of top 3 run types). Uses a `StatsViewWrapper` to own the `@Query` so that `StatsView` itself takes `runs: [DiabloRun]` as a plain parameter.
- **Options tab** (`SettingsView.swift`) — links to `RunTypesView` and `RecommendedMFView`, plus a destructive "Clear All Runs" action.

### Data models

All three models live in the SwiftData container.

**`DiabloRun`** (`ContentView.swift`) — one boss run. Key fields:
- `runTypeName: String` — stored with `@Attribute(originalName: "bossRawValue")` for schema migration.
- `duration: Int` (seconds), `magicFind: Int`, `drops: String`, `date: Date`, `startDate: Date?`.
- `session: DiabloSession?` — back-reference to the owning session.
- `durationInMinutes: Double` — computed convenience property.

**`DiabloSession`** (`ContentView.swift`) — a named grouping of runs sharing a run type.
- `name: String`, `runTypeName: String`, `createdDate: Date`, `startDate/endDate: Date?`, `isActive: Bool`.
- `runs: [DiabloRun]` with `.cascade` delete rule.
- `duration: Int` computed from `endDate - startDate`.
- Sessions are auto-named `"<RunType> session - dd/MM/yyyy"` (with a counter suffix for duplicates) via `makeSessionName(runTypeName:in:)`.

**`RunType`** (`RunType.swift`) — user-configurable run types.
- `name: String`, `defaultRecommendedMF: Int`, `sortOrder: Int`.
- `seedIfNeeded(in:)` inserts six defaults (Andariel 250, Duriel 200, Mephisto 350, Diablo 400, Baal 400, Nihlathak 300) on first launch.

### MF threshold system

`MFSettings` (`SettingsView.swift`) is an `@Observable` class injected via `.environment(mfSettings)` at the root. It layers per-run-type MF overrides on top of `RunType.defaultRecommendedMF`, persisted in `UserDefaults` under keys `"mf_<name>"`. `SessionDetailView` uses `mfSettings.effectiveMF(for:defaultMF:)` to show a green checkmark or yellow warning icon on each run.

### AddRunView flow

`AddRunView` has three phases (`.setup → .active → .postRun`):
1. **Setup** — pick run type (locked if an active session exists) and enter MF.
2. **Active** — live timer display; interactive dismiss is blocked.
3. **Post-run** — shows elapsed time, collects drops; buttons: Save (dismiss), Save & New (loop back to setup within the same session), Save and End Session (marks session `isActive = false`).

On first save within a sheet invocation, a new `DiabloSession` is created unless an `activeSession` was passed in (i.e., a session already exists for that run type).

### State management

`ContentView` holds `@State` for `lastRunType: String` and `lastMF: Int` to pre-populate `AddRunView` across saves — passed as `@Binding`.

Sort options: `SessionSortOption` (date, run count) for the sessions list; `SortOption` (date, duration, magic find) for the runs list inside a session. Both use a bottom-sheet `*SortPickerView` pattern that stays open after selection.
