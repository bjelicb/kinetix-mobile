import 'package:flutter/material.dart';

class HexagonClipper extends CustomClipper<Path> {
  final double cornerCut; // How much to cut from corners (0.0 to 1.0)

  HexagonClipper({this.cornerCut = 0.15});

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final cut = cornerCut * (w < h ? w : h) * 0.5;

    // Start from top-left (with corner cut)
    path.moveTo(cut, 0);
    // Top edge
    path.lineTo(w - cut, 0);
    // Top-right corner cut
    path.lineTo(w, cut);
    // Right edge
    path.lineTo(w, h - cut);
    // Bottom-right corner cut
    path.lineTo(w - cut, h);
    // Bottom edge
    path.lineTo(cut, h);
    // Bottom-left corner cut
    path.lineTo(0, h - cut);
    // Left edge
    path.lineTo(0, cut);
    // Close path
    path.close();

    return path;
  }

  @override
  bool shouldReclip(HexagonClipper oldClipper) => oldClipper.cornerCut != cornerCut;
}
