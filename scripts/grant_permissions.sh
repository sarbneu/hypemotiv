#!/usr/bin/env bash
# Opens the macOS panes where you allow Hermes/Terminal to control the GUI.
# macOS does not let a script tick the toggles — you must click them.
echo "1/3  Accessibility: switch ON Hermes and Terminal"
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
sleep 2

echo "2/3  Screen Recording: switch ON Hermes"
open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
sleep 2

echo "3/3  Input Monitoring (if shown): switch ON Hermes"
open "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"
echo "Done. Toggle the apps ON, then type: retry"
