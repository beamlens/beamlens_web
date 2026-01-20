# Integration Test Harness

This directory contains a minimal Phoenix application for testing BeamlensWeb integration.

## Purpose

To verify that BeamlensWeb can be:
1. Installed as a dependency
2. Mounted in a Phoenix router
3. Served with correct static assets
4. Displayed in a browser

## Setup

```bash
cd test_integration
mix new test_app --sup
```

Then follow the configuration steps in `MANUAL_SETUP.md`

## Running Tests

```bash
cd test_app
mix deps.get
mix test
```

## Manual Testing

Start the server:

```bash
cd test_app
mix phx.server
```

Visit http://localhost:4000/beamlens

## Cleanup

To remove the test app:

```bash
rm -rf test_app
```
