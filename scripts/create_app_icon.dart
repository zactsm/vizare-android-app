import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final logoFile = File('assets/images/logo.png');
  if (!logoFile.existsSync()) {
    print('Error: assets/images/logo.png not found');
    exit(1);
  }

  final logoBytes = logoFile.readAsBytesSync();
  final logo = img.decodeImage(logoBytes);
  if (logo == null) {
    print('Error: Could not decode logo.png');
    exit(1);
  }

  print('Original logo: ${logo.width}x${logo.height}');

  // Find actual content bounding box (trim empty transparent margins)
  int minX = logo.width, maxX = 0, minY = logo.height, maxY = 0;
  for (int y = 0; y < logo.height; y++) {
    for (int x = 0; x < logo.width; x++) {
      final p = logo.getPixel(x, y);
      if (p.a > 15) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  final contentWidth = maxX - minX + 1;
  final contentHeight = maxY - minY + 1;
  print('Content bounding box: $contentWidth x $contentHeight (min: $minX, $minY; max: $maxX, $maxY)');

  final croppedLogo = img.copyCrop(
    logo,
    x: minX,
    y: minY,
    width: contentWidth,
    height: contentHeight,
  );

  // 1024x1024 master canvas
  final iconSize = 1024;
  final master = img.Image(width: iconSize, height: iconSize);

  // Fill with Apple Watch dark obsidian background (#0D0F14)
  final bgDark = img.ColorRgba8(13, 15, 20, 255);
  img.fill(master, color: bgDark);

  // Target size for the trimmed emblem: 680px (approx 66.5% of canvas, perfectly balanced inside iOS / Android rounded masks)
  final targetEmblemSize = 680;
  final scale = targetEmblemSize / (contentWidth > contentHeight ? contentWidth : contentHeight);
  final scaledW = (contentWidth * scale).round();
  final scaledH = (contentHeight * scale).round();

  final resizedLogo = img.copyResize(
    croppedLogo,
    width: scaledW,
    height: scaledH,
    interpolation: img.Interpolation.cubic,
  );

  // Centered position
  final posX = (iconSize - scaledW) ~/ 2;
  final posY = (iconSize - scaledH) ~/ 2;

  img.compositeImage(
    master,
    resizedLogo,
    dstX: posX,
    dstY: posY,
  );

  final outPath = 'assets/icon/app_icon.png';
  File(outPath).writeAsBytesSync(img.encodePng(master));
  print('Successfully generated master app icon ($scaledW x $scaledH emblem on 1024x1024) at $outPath');
}
