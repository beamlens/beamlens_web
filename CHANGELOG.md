# Changelog

## [Unreleased]

## [0.1.0-beta.4] - 2026-02-12

### Fixed
- Asset paths (CSS, JS, favicons, logo) now resolve correctly when mounted under a scoped router path (for example, `scope "/dev"`) — the fix in beta.3 was incomplete and has been replaced with a robust approach using computed absolute paths
- Dashboard logo was not loading due to a hardcoded image path that bypassed the scoped asset routes

### Changed
- Capitalized "beamlens" to "Beamlens" in the dashboard header and page title

## [0.1.0-beta.3] - 2026-02-12

### Fixed
- ~~Asset and favicon paths in the dashboard root layout now resolve correctly when mounted under a scoped router path~~ (incomplete fix, see beta.4)

## [0.1.0-beta.2] - 2025-01-25

### Added
- Filter events by operator - click any operator in the sidebar to see only its events
- Live status indicators for operators and coordinator showing when they're actively running

### Improved
- Sidebar layout with grouped operators section for better organization

## [0.1.0-beta.1] - 2025-01-20

### Added
- Real-time dashboard for Beamlens
- Chat interface for managing Beamlens analysis
- Real-time event tracing
- Coordinator and operator health monitoring
- Cluster support
- JSON export for analysis
- Optional AI-powered summaries via configurable client registry
- Telemetry events for observability
