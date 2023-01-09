import 'dart:typed_data';

import 'pcanvas_base.dart';
import 'pcanvas_bitmap.dart';
import 'pcanvas_bitmap_extension.dart';

class PCanvasFactoryBitmap extends PCanvasFactory {
  static final PCanvasFactoryBitmap instance = PCanvasFactoryBitmap._();

  PCanvasFactoryBitmap._() : super.impl();

  @override
  PCanvas createPCanvas(int width, int height, PCanvasPainter painter,
          {PCanvasPixels? initialPixels}) =>
      PCanvasBitmap(width, height, painter, initialPixels: initialPixels);

  @override
  Uint8List pixelsToPNG(PCanvasPixels pixels) => pixels.pixelsToImagePNG();
}

PCanvasFactory createPCanvasFactoryImpl() => PCanvasFactoryBitmap.instance;
