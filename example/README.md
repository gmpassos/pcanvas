# PCanvas - examples

You can browser the examples at:
- https://github.com/gmpassos/pcanvas/tree/master/example

## Bitmap (in-memory) Example:

- https://github.com/gmpassos/pcanvas/tree/master/example/pcanvas_example_bitmap.dart

## Web Example:

- https://github.com/gmpassos/pcanvas/tree/master/example/pcanvas_example_web

## Basic Example:

```dart
import 'dart:io';

import 'package:pcanvas/pcanvas.dart';

void main() async {
  // Create a canvas of dimension 800x600:
  var pCanvas = PCanvas(800, 600, MyCanvasPainter());

  // Wait the canvas to load:
  await pCanvas.waitLoading();

  // Paint the canvas:
  pCanvas.callPainter();

  // Get the canvas pixels:
  var pixels = await pCanvas.pixels;

  print('-- pixels: $pixels');

  // Convert the canvas to a PNG:
  var pngData = await pCanvas.toPNG();

  print('-- PNG data: ${pngData.lengthInBytes} bytes');

  // Save the PNG to a file:
  var file = File('/tmp/pcanvas_example_bitmap.png');
  file.writeAsBytesSync(pngData);

  print('-- Saved to $file');
}

class MyCanvasPainter extends PCanvasPainter {
  late PCanvasImage img1;
  late PCanvasImage img2;

  @override
  Future<bool> loadResources(PCanvas pCanvas) async {
    var img1URL = 'https://i.postimg.cc/k5TnC1H9/land-scape-1.jpg';
    var img2URL = 'https://i.postimg.cc/L5sFmw5R/canvas-icon.png';

    pCanvas.log('** Loading images...');

    img1 = pCanvas.createCanvasImage(img1URL);
    img2 = pCanvas.createCanvasImage(img2URL);

    var images = [img1, img2];

    await images.loadAll();

    for (var img in images) {
      pCanvas.log('-- Loaded image: $img');
    }

    pCanvas.log('** Loaded images!');

    return true;
  }

  @override
  bool paint(PCanvas pCanvas) {
    // Clear the canvas with `colorGrey`:
    pCanvas.clear(style: PStyle(color: PColor.colorGrey));

    // Draw an image fitting the target area:
    pCanvas.drawImageFitted(img1, 0, 0, pCanvas.width ~/ 2, pCanvas.height);

    // Draw an image centered at `area` with scale `0.15`:
    pCanvas.centered(
      area: PRectangle(0, 0, pCanvas.width ~/ 2, pCanvas.height * 0.50),
      dimension: img2.dimension,
      scale: 0.15,
      (pc, p, sz) => pc.drawImageScaled(img2, p.x, p.y, sz.width, sz.height),
    );

    // Fill a rectangle at (10,10):
    pCanvas.fillRect(
        10, 10, 20, 20, PStyle(color: PColor.colorRed.copyWith(alpha: 0.30)));

    // Fill a rectangle at (40,10):
    pCanvas.fillRect(40, 10, 20, 20, PStyle(color: PColor.colorGreen));

    var fontPR = PFont('Arial', 14);
    var textPR = 'devicePixelRatio: ${pCanvas.devicePixelRatio}';

    // Measure `text`:
    var m = pCanvas.measureText(textPR, fontPR);

    // Draw `text` at (10,55):
    pCanvas.drawText(textPR, 10, 55, fontPR, PStyle(color: PColor.colorBlack));

    // Stroke a rectangle around the `text`:
    pCanvas.strokeRect(10 - 2, 55 - 2, m.actualWidth + 4, m.actualHeight + 4,
        PStyle(color: PColor.colorYellow));

    var fontHello = PFont('Arial', 24);
    var textHello = 'Hello World!';

    // Draw a text and a shadow at the center of `area`:
    pCanvas.centered(
      area: PRectangle(0, 0, pCanvas.width ~/ 2, pCanvas.height * 0.30),
      dimension: pCanvas.measureText(textHello, fontHello),
      (pc, p, sz) {
        pc.drawText(textHello, p.x + 2, p.y + 2, fontHello,
            PStyle(color: PColorRGBA(0, 0, 0, 0.30)));
        pc.drawText(
            textHello, p.x, p.y, fontHello, PStyle(color: PColor.colorBlue));
      },
    );

    var path = [100, 10, const Point(130, 25), 100, 40];

    // Stroke a `path`:
    pCanvas.strokePath(path, PStyle(color: PColor.colorRed, size: 3),
        closePath: true);

    return true;
  }
}
```
