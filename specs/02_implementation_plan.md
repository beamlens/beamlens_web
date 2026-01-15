# Implementation Plan for Hex.pm Release

## Status: Research Phase Complete

### Completed
- ✅ Explored codebase structure
- ✅ Verified beamlens v0.2.0 exists on Hex
- ✅ Validated integration test harness works
- ✅ Documented current state
- ✅ Assessed Hex.pm readiness

## Implementation Steps

### Phase 1: Add Unit Tests (CRITICAL)

#### 1.1 Component Tests
Add tests for all 8 component modules in `lib/beamlens_web/components/`:

- `core_components.ex`
  - Theme toggle functionality
  - Timezone display
  - Utility functions

- `event_components.ex`
  - Event list rendering
  - Event detail display
  - Filtering logic

- `notification_components.ex`
  - Notification card rendering
  - Filter handling
  - Clear actions

- `operator_components.ex`
  - Operator status display
  - State badge rendering
  - Control buttons

- `coordinator_components.ex`
  - Coordinator status display
  - Iteration tracking

- `trigger_components.ex`
  - Analysis trigger form
  - Validation

- `sidebar_components.ex`
  - Navigation rendering
  - Active state handling

- `icons.ex`
  - Icon component rendering

#### 1.2 Store Tests
Add tests for all 3 store modules:

- `event_store.ex`
  - Event storage and retrieval
  - Filter state management
  - Search functionality

- `notification_store.ex`
  - Notification storage
  - Filter state management

- `insight_store.ex`
  - Insight storage
  - State management

#### 1.3 Core Module Tests
- `beamlens_web.ex` - Main module helpers
- `router.ex` - Route macro
- `application.ex` - Supervisor
- `assets.ex` - Asset serving

### Phase 2: Add LiveView Tests

#### 2.1 DashboardLive Tests
- `test/dashboard_live_test.exs`
  - Mount behavior
  - Handle event callbacks
  - State updates
  - Operator interactions
  - Filter changes
  - Theme switching

### Phase 3: Add CHANGELOG.md

Create comprehensive changelog following Keep a Changelog format:
- Added section for v0.1.0
- Document all features
- Note installation instructions
- Include breaking changes (none for v0.1.0)

### Phase 4: Run Test Suite

- `mix test` - Ensure all tests pass
- `mix test.coverage` - Check coverage (target >80%)
- Fix any failing tests

### Phase 5: Code Quality Checks

- `mix format` - Format all code
- `mix hex.build` - Validate package can be built
- Review any warnings

### Phase 6: Final Validation

- Re-run integration test harness
- Manual smoke test of dashboard
- Verify all documentation is accurate

## Commit Strategy

Each step should be committed separately with clear messages:

1. `feat: add component tests for [component_name]`
2. `feat: add store tests for [store_name]`
3. `feat: add LiveView tests for DashboardLive`
4. `docs: add CHANGELOG.md for v0.1.0`
5. `test: validate test suite passes`
6. `chore: run code formatting`
7. `chore: validate hex.build`

## Test Coverage Goals

- **Target:** >80% coverage
- **Minimum:** >70% coverage
- **Critical paths:** 100% coverage

## Success Criteria

- [ ] All unit tests pass
- [ ] Integration tests pass
- [ ] Test coverage >80%
- [ ] `mix format` produces no changes
- [ ] `mix hex.build` succeeds
- [ ] CHANGELOG.md created
- [ ] Manual smoke test passes

## Estimated Scope

- **Component tests:** ~8 commits (one per component)
- **Store tests:** ~3 commits (one per store)
- **LiveView tests:** ~1 commit
- **Changelog:** ~1 commit
- **Validation:** ~2 commits
- **Total:** ~15 commits

## Blocking Issues

None identified. Ready to proceed with implementation.

## Next Action

Start with Phase 1.1: Add component tests beginning with `core_components.ex`
