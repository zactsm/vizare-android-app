import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  const width = 96;
  const height = 120;
  final image = img.Image(width: width, height: height, numChannels: 4);

  // Pin head center: (48, 44), radius: 36
  const centerX = 48.0;
  const centerY = 42.0;
  const headRadius = 34.0;
  const tipX = 48.0;
  const tipY = 110.0;

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final dx = x - centerX;
      final dy = y - centerY;
      final distToHeadCenter = sqrt(dx * dx + dy * dy);

      // Check if pixel is inside the teardrop pin geometry
      bool inPin = false;
      if (distToHeadCenter <= headRadius) {
        inPin = true;
      } else if (y >= centerY && y <= tipY) {
        // Tangent triangle from circle to tip
        final tangentAngle = asin(headRadius / (tipY - centerY));
        final angleFromTip = atan2((x - tipX).abs(), tipY - y);
        if (angleFromTip <= tangentAngle) {
          inPin = true;
        }
      }

      if (inPin) {
        // Compute champagne gold gradient from top (#FFF0BD) to middle (#D4AF37) to bottom (#9A7010)
        final t = (y / tipY).clamp(0.0, 1.0);
        int r, g, b;
        if (t < 0.4) {
          final factor = t / 0.4;
          r = (255 * (1 - factor) + 212 * factor).round(); // #FFF0BD -> #D4AF37
          g = (240 * (1 - factor) + 175 * factor).round();
          b = (189 * (1 - factor) + 55 * factor).round();
        } else {
          final factor = (t - 0.4) / 0.6;
          r = (212 * (1 - factor) + 154 * factor).round(); // #D4AF37 -> #9A7010
          g = (175 * (1 - factor) + 112 * factor).round();
          b = (55 * (1 - factor) + 16 * factor).round();
        }

        // Inner dark core (center cutout for luxury emblem look)
        if (distToHeadCenter <= 18.0) {
          if (distToHeadCenter <= 8.0) {
            // Gold center beacon dot
            r = 243;
            g = 229;
            b = 171;
          } else {
            // Obsidian dark core ring
            r = 14;
            g = 17;
            b = 24;
          }
        }

        image.setPixelRgba(x, y, r, g, b, 255);
      }
    }
  }

  final outPath = 'assets/images/gold_map_pin.png';
  File(outPath).writeAsBytesSync(img.encodePng(image));
  print('Successfully created $outPath');
}
