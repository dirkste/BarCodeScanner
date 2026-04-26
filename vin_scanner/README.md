# VIN Scanner

Flutter app that scans vehicle VIN barcodes (Code 39 / Code 128) from door jamb stickers using the device camera.

## Quick orientation

- **Requirements & exit criteria** — see [`../REQUIREMENTS.md`](../REQUIREMENTS.md)
- **Architecture decisions & handoff notes** — see [`../HANDOFF.md`](../HANDOFF.md)
- **Entry point** — `lib/main.dart` (DI composition root + camera permission gate)
- **Abstraction boundary** — `lib/services/scanner_service.dart` (`ScannerService` interface)
- **Concrete implementation** — `lib/services/mobile_scanner_service.dart` (`MobileScannerService`)
- **Tests** — `test/` mirrors `lib/` structure; run with `flutter test`

## Run on device

```sh
flutter run -d <device-id>
```
