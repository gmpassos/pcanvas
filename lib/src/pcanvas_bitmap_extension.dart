import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'pcanvas_base.dart';

extension PFontExtension on PFont {
  img.BitmapFont toBitmapFontFamily() {
    if (size >= 36) {
      return img.arial48;
    } else if (size >= 19) {
      return img.arial24;
    } else {
      return img.arial14;
    }
  }

  img.BitmapFont toBitmapFont() {
    var f = toBitmapFontFamily();
    if (bold) f.bold = true;
    if (italic) f.italic = true;
    f.antialias = true;
    return f;
  }
}

extension PCanvasPixelsExtension on PCanvasPixels {
  img.Color getImageColor(int x, int y) {
    var pixels = this;

    var p = pixels.pixel(x, y);

    int r, g, b, a;

    if (pixels is PCanvasPixelsRGBA) {
      r = (p >> 24) & 0xff;
      g = (p >> 16) & 0xff;
      b = (p >> 8) & 0xff;
      a = ((p) & 0xff);
    } else if (pixels is PCanvasPixelsARGB) {
      r = (p >> 16) & 0xff;
      g = (p >> 8) & 0xff;
      b = (p) & 0xff;
      a = ((p >> 24) & 0xff);
    } else if (pixels is PCanvasPixelsABGR) {
      r = (p) & 0xff;
      g = (p >> 8) & 0xff;
      b = (p >> 16) & 0xff;
      a = ((p >> 24) & 0xff);
    } else {
      throw StateError("Can't pixels type: ${pixels.runtimeType} > $pixels");
    }

    return img.ColorUint32.rgba(r, g, b, a);
  }

  Uint8List pixelsToImagePNG() {
    final pixels = this;

    var w = pixels.width;
    var h = pixels.height;

    var bitmap = img.Image(
        width: w,
        height: h,
        format: img.Format.uint8,
        numChannels: 4,
        withPalette: false);

    for (var y = 0; y < h; ++y) {
      for (var x = 0; x < w; ++x) {
        var p = pixels.getImageColor(x, y);
        bitmap.setPixel(x, y, p);
      }
    }

    return img.encodePng(bitmap, singleFrame: true);
  }
}

extension ImageExtension on img.Image {
  Uint8List get dataAsUint8List {
    var imageData = data as img.ImageDataUint8;
    var dataUint8 = imageData.data;
    return dataUint8;
  }
}
