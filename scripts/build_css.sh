#!/bin/bash
# Build CSS for beamlens_web library
# Run from project root: ./scripts/build_css.sh
#
# This builds the Tailwind CSS for distribution.
# The output is committed to priv/static/assets/app.css

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT/assets"

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
  echo "Installing npm dependencies..."
  npm install
fi

echo "Building CSS with Tailwind..."

# Build based on argument
if [ "$1" == "--watch" ]; then
  npm run watch
elif [ "$1" == "--minify" ]; then
  npm run build:minify
else
  npm run build
fi

echo "CSS built successfully: priv/static/assets/app.css"
