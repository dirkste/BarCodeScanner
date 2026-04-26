# VIN Scanner — Agent Handoff Document
**Date:** 2026-04-26  
**Status:** Phase 1 active — vehicle barcode detection is the remaining blocker

---

## Project Summary

Flutter barcode scanner app (Android, Phase 1 POC). Scans barcodes and displays the raw value + elapsed scan time. Built with `mobile_scanner ^5.0.0` (actual: 5.2.3) and `get_it ^7.0.0`. All requirements in `REQUIREMENTS.md`.

**Key files:**
- `c:\Code\VinScanner\REQUIREMENTS.md` — authoritative requirements (v0.4)
- `c:\Code\VinScanner\vin_scanner\lib\services\scanner_service.dart` — abstract interface + ScanResult
- `c:\Code\VinScanner\vin_scanner\lib\services\mobile_scanner_service.dart` — concrete implementation
- `c:\Code\VinScanner\vin_scanner\lib\ui\scanner_screen.dart` — main UI
- `c:\Code\VinScanner\vin_scanner\lib\main.dart` — app entry point + get_it registration
- `c:\Code\VinScanner\vin_scanner\test\` — 14 tests, all passing

---

## Current App Behaviour

1. App opens → camera preview is live immediately
2. User aims at barcode
3. User taps **Start Scan** button → timer starts (`startScan()` called)
4. ML Kit decodes barcode → result overlay shows raw value + elapsed ms
5. User taps **Scan Again** → returns to ready state (camera still live)
6. After 10s with no result → inline amber hint text appears ("No VIN detected yet — try moving closer or improving lighting")

**No VIN filter** — accepts any barcode format/value.

---

## Test Results (Today's Field Tests)

| Test | Format | Value | Time | Notes |
|------|--------|-------|------|-------|
| Product UPC | Code39 | `5418223` | **214ms** ✓ | Under 1s target |
| MVA barcode | UPC-A | `071153003507` | **185ms** ✓ | Under 1s target |
| Vehicle door jamb VIN | — | — | **No detection** ✗ | See below |
| Printed VIN sample (internet) | Code39 | — | **Instant** ✓ | Confirmed format works |
| Printed VIN from vehicle photo crop | Code39 | — | **Instant** ✓ | Confirmed barcode is readable |

---

## Root Cause: Vehicle Barcode Failure

The vehicle door jamb sticker was photographed (see `HANDOFF_vehicle_sticker.jpg` if present, or ask user). Key observations:

1. **Sticker is rotated 90°** on the door jamb (text/barcode reads sideways)
2. **Barcode is surrounded by dense text** — tire pressures, weight ratings, VIN text, trim codes all on the same sticker. ML Kit scans the whole frame and the surrounding text creates noise.
3. **Door jamb is shadowed/dark** — recessed area with poor lighting
4. **Barcode itself is intact** — confirmed readable when isolated and printed

When the cropped barcode was printed and scanned, it worked instantly. This confirms:
- The barcode format is supported (Code 39 or Code 128)
- The barcode content is valid
- **The problem is environmental: noise + lighting**

---

## Confirmed Dead Ends

- **`scanWindow` parameter on `MobileScanner` widget** — tried `Rect.fromLTRB(0.075, 0.41, 0.925, 0.59)` (normalized 0-1, matching the targeting box: 85% wide × 18% tall, centered). This **completely killed detection** on the user's Samsung S21U (Android 15, API 35). No `onDetect` calls at all. Cause unknown — possibly a bug in mobile_scanner 5.2.3 on Android 15. Reverted.
- **VIN regex filter** — was filtering out non-VIN barcodes but removed at user's request (app may scan non-VIN barcodes too).

---

## What Needs To Be Done Next

### Priority 1 — Fix vehicle barcode detection

**Option A: Fix `scanWindow`** (right solution, broken implementation)
- Need to understand why `scanWindow` kills detection on Android 15
- Check `mobile_scanner` 5.2.3 Android source: `MobileScanner.kt`, `BarcodeHandler.kt`, `scan_window_calculation.dart`
- The coordinate system may be wrong, or there's a known Android 15 bug
- If `scanWindow` works, user can aim the targeting box at just the barcode, excluding surrounding text noise

**Option B: Torch/flashlight toggle** (addresses shadow issue, not the noise issue)
- Add a torch button to `ScannerScreen`
- Use `MobileScannerController` with `torchEnabled` property
- Currently `MobileScanner` is created without a controller — need to add one

**Option C: Both** — most complete solution

### Priority 2 — Performance tuning (if scanWindow alone doesn't solve it)
- Try `DetectionSpeed.unrestricted` (processes every frame, not skipped frames)
- Explicitly declare formats: Code39 + Code128 only (per F-04)
- Both are parameters on the `MobileScanner` widget

---

## Diagnostic Logging Currently In Place

`mobile_scanner_service.dart` logs to logcat under `I/flutter`:
```
[SCAN_DEBUG] onDetect fired: N barcode(s) in frame
[SCAN_DEBUG] first barcode: format=BarcodeFormat.XXX, raw=VALUE
[SCAN_DEBUG] ignored — result already captured
[SCAN_DEBUG] ignored — startScan not called
[SCAN_DEBUG] rejected — null or empty raw value
[SCAN_PERF] decoded in Xms
```

To monitor: `adb logcat | grep "SCAN_DEBUG\|SCAN_PERF"`

Key insight: during the failed vehicle scan, there were **zero SCAN_DEBUG lines** — ML Kit never called `onDetect` at all. It's not failing to decode; it's failing to detect.

---

## Dev Environment

- Flutter: 3.41.7 stable, installed at `C:\flutter`
- Run flutter: `/c/flutter/bin/flutter`
- Device: Samsung SM G998U1 (S21 Ultra), Android 15 (API 35), device ID `R5CR50H7MQK`
- Deploy: `cd /c/Code/VinScanner/vin_scanner && /c/flutter/bin/flutter run -d R5CR50H7MQK`
- Test: `cd /c/Code/VinScanner/vin_scanner && /c/flutter/bin/flutter test`
- adb: `C:\Users\dirks\AppData\Local\Android\Sdk\platform-tools\adb.exe`

---

## Test Suite

14 tests, all passing. Run with `flutter test` from `vin_scanner/` directory.

Key test files:
- `test/services/mobile_scanner_service_test.dart` — 5 tests
- `test/services/scanner_service_test.dart` — 3 tests  
- `test/ui/scanner_screen_test.dart` — 6 tests (uses `_FakeScannerService` + `cameraBuilder` injection)

---

## Phase 1 Exit Criteria Status

| Criterion | Status |
|-----------|--------|
| App successfully decodes a real VIN from a physical vehicle | ✗ Not yet |
| Scan-to-decode time confirmed under 1s in field conditions | ✓ 185ms and 214ms on non-vehicle barcodes |
| Abstraction layer in place, swap validated as feasible | ✓ |

Phase 1 is blocked on vehicle barcode detection. Everything else is working.
