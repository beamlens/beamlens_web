# Quick Release Checklist - BeamlensWeb v0.1.0

## Pre-Release Verification

```bash
# Compile
mix compile

# Run tests
mix test

# Build Hex package
mix hex.build

# Verify files included
# Should see: lib, priv/static, config, docs
```

## Publishing Steps

### 1. Create and Push Tag
```bash
git tag -a v0.1.0 -m "Release v0.1.0 - Initial Hex.pm release"
git push origin v0.1.0
```

### 2. Publish to Hex
```bash
mix hex.publish
```

You'll need a Hex.pm account. If you don't have one:
```bash
mix hex.user register
```

### 3. Verify Release
Visit: https://hex.pm/packages/beamlens_web

## What's Included in This Release

### Fixed Issues
- ✅ Changed beamlens dependency from local path to Hex package
- ✅ Removed early access gate (compile-time check)
- ✅ Removed duplicate code and simplified logic
- ✅ Removed unused component attributes

### Package Contents
- 17 source files in lib/
- Static assets (CSS, images, favicons)
- Complete documentation
- Apache-2.0 license

### Known Limitations
- Test coverage is minimal (acceptable for 0.1.0)
- No integration test harness (documented manual procedure)
- Uses maps instead of structs (planned for 0.2.0)

## After Release

1. **Update README** - Add Hex badge and actual installation counts
2. **Monitor Issues** - Watch for user-reported problems
3. **Plan 0.2.0** - Implement struct conversion and more tests

## Emergency Rollback

If critical issues are found:

```bash
# Retract from Hex
mix hex.retract beamlens_web 0.1.0

# Or publish a patch quickly
# Bump version to 0.1.1 in mix.exs
# Fix the issue
# Release 0.1.1
```

## Contact

For issues or questions about this release, refer to:
- specs/00_SUMMARY.md - Complete preparation summary
- specs/03_hex_package_validation.md - Validation details and integration testing
