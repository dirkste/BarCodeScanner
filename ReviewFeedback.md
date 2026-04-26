Issues / risks
Leaky abstraction in the UI — scanner_screen.dart:73-78 does if (service is MobileScannerService) service.onBarcodeDetected(capture). This violates A-03 (UI is now coupled to the concrete class) and silently no-ops with any other implementation. The ScannerService interface should expose something like onBarcodeDetected(BarcodeCapture) — or better, the concrete service should own the MobileScanner widget construction so the UI never sees BarcodeCapture at all. The latter is the cleaner fix and would also unblock the swap test in your exit criteria #3.

mobile_scanner types leak through simulateDecode — fine for now, but reinforces #1: as soon as you add a second backend, that test hook stops being portable.

MobileScannerService.dispose() is never called. It's not on the interface and main.dart registers as singleton, so the StreamController lives forever. Low-impact today, but add dispose() to the interface or use registerLazySingleton + getIt.unregister.

No camera permission flow actually exists. cameraPermissionDenied is a constructor flag that nothing ever sets to true in production — mobile_scanner handles permission internally and your fallback UI is unreachable. E-02 is "passing" only in tests. Either wire up permission_handler or rely on mobile_scanner's built-in error stream and surface it.

No format restriction (F-04). You're accepting all formats. The handoff already flagged this — declaring formats: [BarcodeFormat.code39, BarcodeFormat.code128] should both satisfy F-04 and reduce the noise problem on the door jamb sticker (ML Kit will stop trying to decode the surrounding QR/data-matrix candidates).

No MobileScannerController. You construct MobileScanner(onDetect: ...) with defaults. To do any of the next-step work — torch toggle, format restriction, detectionSpeed, autofocus mode — you need a controller. This is the single biggest unlock for Priority 1 in the handoff.

scanWindow dead-end is plausibly real. Known issue — on Android with mobile_scanner 5.x there have been reports of scanWindow silently disabling detection when the controller's cameraResolution and the widget's BoxFit interact badly. If you revisit, set an explicit cameraResolution on the controller and fit: BoxFit.cover on the widget before retrying the scan window.

pubspec.yaml SDK constraint is ^3.11.5 but REQUIREMENTS says >=3.0.0. Not a bug, just inconsistent — narrow the requirements doc or loosen the pubspec.

README is the default Flutter template. Worth a 10-line replacement pointing at REQUIREMENTS/HANDOFF so a fresh agent lands oriented.


Suggested next moves (in order)
Add a MobileScannerController with formats: [code39, code128] and detectionSpeed: DetectionSpeed.noDuplicates (or unrestricted if 5 fps isn't enough).
Move widget construction into the service (Widget buildPreview() on the interface) — fixes the leaky is MobileScannerService check and unblocks library-swap validation.
Add a torch toggle button bound to controller.toggleTorch() — addresses the door-jamb shadow.
Retry scanWindow only after #1 + BoxFit.cover is in place.
Phase 1 is genuinely close. The remaining failure is environmental, not architectural — and the architecture is set up correctly to absorb a pivot if you need one.