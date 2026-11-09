import 'package:flutter/material.dart';

class QrCodeBox extends StatelessWidget {
  const QrCodeBox({
    required this.data,
    this.size = 190,
    super.key,
  });

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.14),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: CustomPaint(
      painter: _QrMatrixPainter(data: data),
      size: Size.square(size - 28),
    ),
  );
}

class _QrMatrixPainter extends CustomPainter {
  _QrMatrixPainter({required this.data});

  final String data;
  static const int _gridSize = 25;

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / _gridSize;
    final paint = Paint()
      ..color = const Color(0xFF111827)
      ..style = PaintingStyle.fill;

    final matrix = _buildMatrix(data);
    for (var r = 0; r < _gridSize; r++) {
      for (var c = 0; c < _gridSize; c++) {
        if (!matrix[r][c]) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            c * cellSize,
            r * cellSize,
            cellSize + 0.35,
            cellSize + 0.35,
          ),
          paint,
        );
      }
    }
  }

  List<List<bool>> _buildMatrix(String payload) {
    final grid = List.generate(
      _gridSize,
      (_) => List<bool>.filled(_gridSize, false),
    );
    final reserved = List.generate(
      _gridSize,
      (_) => List<bool>.filled(_gridSize, false),
    );

    void placeFinder(int top, int left) {
      for (var r = -1; r <= 7; r++) {
        for (var c = -1; c <= 7; c++) {
          final rr = top + r;
          final cc = left + c;
          if (rr < 0 || rr >= _gridSize || cc < 0 || cc >= _gridSize) continue;
          reserved[rr][cc] = true;
          final isOuter =
              r >= 0 &&
              r <= 6 &&
              c >= 0 &&
              c <= 6 &&
              (r == 0 || r == 6 || c == 0 || c == 6);
          final isInner = r >= 2 && r <= 4 && c >= 2 && c <= 4;
          grid[rr][cc] = isOuter || isInner;
        }
      }
    }

    placeFinder(0, 0);
    placeFinder(0, _gridSize - 7);
    placeFinder(_gridSize - 7, 0);

    // Alignment pattern at bottom-right
    const alignRow = _gridSize - 9;
    const alignCol = _gridSize - 9;
    for (var r = 0; r < 5; r++) {
      for (var c = 0; c < 5; c++) {
        final rr = alignRow + r;
        final cc = alignCol + c;
        reserved[rr][cc] = true;
        final isBorder = r == 0 || r == 4 || c == 0 || c == 4;
        final isCenter = r == 2 && c == 2;
        grid[rr][cc] = isBorder || isCenter;
      }
    }

    // Timing patterns
    for (var i = 8; i < _gridSize - 8; i++) {
      reserved[6][i] = true;
      reserved[i][6] = true;
      grid[6][i] = i.isEven;
      grid[i][6] = i.isEven;
    }

    final codeUnits = payload.isEmpty ? [78, 85, 84, 82, 73] : payload.codeUnits;
    var bitIndex = 0;
    var hash = 2166136261;
    for (final unit in codeUnits) {
      hash = ((hash ^ unit) * 16777619) & 0x7fffffff;
    }

    for (var r = 0; r < _gridSize; r++) {
      for (var c = 0; c < _gridSize; c++) {
        if (reserved[r][c]) continue;
        final byte = codeUnits[bitIndex % codeUnits.length];
        final shift = bitIndex % 8;
        final bit = ((byte >> shift) ^ ((r * 31 + c * 17 + hash) >> (shift))) & 1;
        grid[r][c] = bit == 1;
        bitIndex++;
      }
    }
    return grid;
  }

  @override
  bool shouldRepaint(covariant _QrMatrixPainter oldDelegate) =>
      oldDelegate.data != data;
}
