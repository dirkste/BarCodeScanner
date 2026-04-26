import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/mobile_scanner_service.dart';
import '../services/scanner_service.dart';

class ScannerScreen extends StatefulWidget {
  final bool cameraPermissionDenied;

  /// Overrides the camera widget — used in tests to avoid real hardware.
  final Widget Function(void Function(BarcodeCapture))? cameraBuilder;

  const ScannerScreen({
    super.key,
    this.cameraPermissionDenied = false,
    this.cameraBuilder,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late final ScannerService _scannerService;
  bool _scanning = false;
  ScanResult? _result;
  bool _showHint = false;
  Timer? _hintTimer;
  StreamSubscription<ScanResult>? _subscription;

  @override
  void initState() {
    super.initState();
    _scannerService = GetIt.instance<ScannerService>();
    // Camera opens but timer doesn't start until user taps Start Scan.
  }

  void _startScanning() {
    _hintTimer?.cancel();
    setState(() {
      _scanning = true;
      _result = null;
      _showHint = false;
    });
    _scannerService.startScan();

    _hintTimer = Timer(const Duration(seconds: 10), () {
      if (_result == null && mounted) {
        setState(() => _showHint = true);
      }
    });

    _subscription?.cancel();
    _subscription = _scannerService.results.listen((result) {
      _hintTimer?.cancel();
      if (mounted) setState(() => _result = result);
    });
  }

  void _resetScan() {
    _hintTimer?.cancel();
    _subscription?.cancel();
    setState(() {
      _scanning = false;
      _result = null;
      _showHint = false;
    });
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    final service = _scannerService;
    if (service is MobileScannerService) {
      service.onBarcodeDetected(capture);
    }
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _subscription?.cancel();
    _scannerService.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cameraPermissionDenied) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Camera permission denied. Please enable camera access in Settings.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final result = _result;
    final cameraWidget = widget.cameraBuilder != null
        ? widget.cameraBuilder!(_onBarcodeDetected)
        : MobileScanner(onDetect: _onBarcodeDetected);

    return Scaffold(
      body: Stack(
        children: [
          cameraWidget,
          if (result != null)
            _ResultOverlay(result: result, onRescan: _resetScan)
          else if (_scanning)
            _ScanningOverlay(showHint: _showHint)
          else
            _ReadyOverlay(onStart: _startScanning),
        ],
      ),
    );
  }
}

class _ReadyOverlay extends StatelessWidget {
  final VoidCallback onStart;

  const _ReadyOverlay({required this.onStart});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final boxW = size.width * 0.85;
    final boxH = size.height * 0.18;

    return Stack(
      children: [
        CustomPaint(
          size: Size(size.width, size.height),
          painter: _TargetingPainter(boxW: boxW, boxH: boxH),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: size.height * 0.5 - boxH / 2 - 56),
              SizedBox(width: boxW, height: boxH),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text('Start Scan'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScanningOverlay extends StatelessWidget {
  final bool showHint;

  const _ScanningOverlay({this.showHint = false});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final boxW = size.width * 0.85;
    final boxH = size.height * 0.18;

    return Stack(
      children: [
        CustomPaint(
          size: Size(size.width, size.height),
          painter: _TargetingPainter(boxW: boxW, boxH: boxH),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: size.height * 0.5 - boxH / 2 - 56),
              SizedBox(
                width: boxW,
                height: boxH,
                // transparent centre — painter draws the frame
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  showHint
                      ? 'No VIN detected yet — try moving closer or improving lighting'
                      : 'Align barcode within the box',
                  style: TextStyle(
                    color: showHint ? Colors.amber : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class _TargetingPainter extends CustomPainter {
  final double boxW;
  final double boxH;

  const _TargetingPainter({required this.boxW, required this.boxH});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final l = cx - boxW / 2;
    final t = cy - boxH / 2;
    final r = cx + boxW / 2;
    final b = cy + boxH / 2;

    final dim = Paint()..color = Colors.black.withValues(alpha: 0.55);
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, t), dim);
    canvas.drawRect(Rect.fromLTRB(0, b, size.width, size.height), dim);
    canvas.drawRect(Rect.fromLTRB(0, t, l, b), dim);
    canvas.drawRect(Rect.fromLTRB(r, t, size.width, b), dim);

    const cLen = 24.0;
    final bracket = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // top-left
    canvas.drawLine(Offset(l, t + cLen), Offset(l, t), bracket);
    canvas.drawLine(Offset(l, t), Offset(l + cLen, t), bracket);
    // top-right
    canvas.drawLine(Offset(r - cLen, t), Offset(r, t), bracket);
    canvas.drawLine(Offset(r, t), Offset(r, t + cLen), bracket);
    // bottom-left
    canvas.drawLine(Offset(l, b - cLen), Offset(l, b), bracket);
    canvas.drawLine(Offset(l, b), Offset(l + cLen, b), bracket);
    // bottom-right
    canvas.drawLine(Offset(r - cLen, b), Offset(r, b), bracket);
    canvas.drawLine(Offset(r, b), Offset(r, b - cLen), bracket);
  }

  @override
  bool shouldRepaint(_TargetingPainter old) => old.boxW != boxW || old.boxH != boxH;
}

class _ResultOverlay extends StatelessWidget {
  final ScanResult result;
  final VoidCallback onRescan;

  const _ResultOverlay({required this.result, required this.onRescan});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('VIN Decoded', style: TextStyle(color: Colors.green, fontSize: 18)),
              const SizedBox(height: 16),
              Text(
                result.rawValue,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '${result.elapsedMs}ms',
                style: const TextStyle(color: Colors.amber, fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(onPressed: onRescan, child: const Text('Scan Again')),
            ],
          ),
        ),
      ),
    );
  }
}

