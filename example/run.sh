#!/bin/bash
rm -r ~/Android/flutter/bin/cache/flutter_tools.stamp
flutter pub get
flutter run --debug