import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  final Function(String) onScanned;

  const QrScannerScreen({super.key, required this.onScanned});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _scanned = false;
  bool _torchOn = false;
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final squareSize = screenWidth * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_scanned) return;
              final barcode = capture.barcodes.firstOrNull;
              final value = barcode?.rawValue;
              final isContactKey = value != null && value.length == 64;
              final isGroupInvite =
                  value != null &&
                  value.startsWith('{') &&
                  value.contains('"group_invite_link"');
              if (isContactKey || isGroupInvite) {
                setState(() => _scanned = true);
                Navigator.pop(context);
                widget.onScanned(value);
              }
            },
          ),
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.6),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: squareSize,
                    height: squareSize,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: SizedBox(
              width: squareSize,
              height: squareSize,
              child: CustomPaint(painter: _CornerBracketPainter()),
            ),
          ),
          Center(
            child: Transform.translate(
              offset: Offset(0, squareSize / 2 + 24),
              child: const Text(
                'Align the QR code within the frame',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () async {
                  await _controller.toggleTorch();
                  setState(() => _torchOn = !_torchOn);
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _torchOn
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/flashlight.svg',
                      width: 26,
                      height: 26,
                      colorFilter: ColorFilter.mode(
                        _torchOn ? Colors.black : Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                'Scan QR Code',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const bracketLength = 24.0;
    const radius = 16.0;

    canvas.drawPath(
      Path()
        ..moveTo(0, bracketLength + radius)
        ..lineTo(0, radius)
        ..arcToPoint(Offset(radius, 0), radius: const Radius.circular(radius))
        ..lineTo(bracketLength + radius, 0),
      paint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(size.width - bracketLength - radius, 0)
        ..lineTo(size.width - radius, 0)
        ..arcToPoint(
          Offset(size.width, radius),
          radius: const Radius.circular(radius),
        )
        ..lineTo(size.width, bracketLength + radius),
      paint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - bracketLength - radius)
        ..lineTo(0, size.height - radius)
        ..arcToPoint(
          Offset(radius, size.height),
          radius: const Radius.circular(radius),
          clockwise: false,
        )
        ..lineTo(bracketLength + radius, size.height),
      paint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(size.width - bracketLength - radius, size.height)
        ..lineTo(size.width - radius, size.height)
        ..arcToPoint(
          Offset(size.width, size.height - radius),
          radius: const Radius.circular(radius),
          clockwise: false,
        )
        ..lineTo(size.width, size.height - bracketLength - radius),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
