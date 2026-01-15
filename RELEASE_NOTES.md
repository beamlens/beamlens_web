# BeamlensWeb v0.1.0 Release Notes

## Quick Start

To publish to Hex.pm:

```bash
# 1. Ensure you're on main branch
git checkout main

# 2. Create and push tag
git tag -a v0.1.0 -m "Release v0.1.0 - Initial BeamlensWeb dashboard"
git push origin v0.1.0

# 3. Publish to Hex.pm
mix hex.publish
```

## What's Included

✅ **43 tests passing**
✅ **Comprehensive documentation**
✅ **CHANGELOG.md**
✅ **Integration test harness**
✅ **All dependencies verified**

## Package Contents

- Phoenix LiveView dashboard for BeamLens monitoring
- Real-time event streaming and filtering
- Multi-node cluster support
- Theme customization (light/dark/system)
- JSON export functionality
- Pre-built static assets

## Verification

All checks passed:
- [x] `mix test` - 43 tests, 0 failures
- [x] `mix format` - Code formatted
- [x] `mix hex.build` - Package builds successfully
- [x] `bash test_integration/setup_and_test.sh` - Integration tests pass

## Dependencies

All verified available on Hex.pm:
- beamlens ~> 0.2 ✅
- phoenix ~> 1.7 ✅
- phoenix_live_view ~> 1.0 ✅
- phoenix_html ~> 4.0 ✅
- req ~> 0.5 ✅

## Next Steps

After publishing:
1. Verify package on https://hex.pm
2. Update documentation with installation link
3. Announce release
4. Monitor for issues

## Contact

For issues or questions:
- GitHub: https://github.com/beamlens/beamlens_web
- Docs: See README.md and CHANGELOG.md
