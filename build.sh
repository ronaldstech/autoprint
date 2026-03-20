#!/bin/bash

# Stop on error
set -e

# Clone Flutter SDK
git clone https://github.com/flutter/flutter.git --depth 1

# Add Flutter to PATH
export PATH="$PATH:$(pwd)/flutter/bin"

# Verify installation
flutter --version

# Enable web
flutter config --enable-web

# Get dependencies
flutter pub get

# Build web app
flutter build web