---
description: Run all review agents against current branch changes
---

Run all ten review agents to validate the current branch changes:

1. Use the **docs-reviewer** agent to check documentation completeness
2. Use the **changelog-reviewer** agent to verify CHANGELOG.md is up to date
3. Use the **test-reviewer** agent to ensure test coverage is adequate
4. Use the **comment-reviewer** agent to find non-critical inline comments
5. Use the **type-reviewer** agent to find map usage where structs should be used
6. Use the **safety-reviewer** agent to check production safety, sensitive data, and backwards compatibility
7. Use the **elixir-idiom-reviewer** agent to find anti-patterns that fight the BEAM
8. Use the **architecture-reviewer** agent to verify architecture docs match the code
9. Use the **release-reviewer** agent to inspect hex package contents for inappropriate or missing files
10. Use the **code-simplifier** agent to find unnecessary complexity and over-engineering

Run all ten agents and provide a consolidated summary of findings.
