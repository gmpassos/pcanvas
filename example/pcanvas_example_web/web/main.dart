import 'dart:async';
// ignore: deprecated_member_use
import 'dart:html';

import 'package:pcanvas/pcanvas.dart';

void main() async {
  var divOutput = querySelector('#output') as DivElement;

  // The canvas parent with `background-color: #333`:
  divOutput.style.backgroundColor = '#333';

  // Create a canvas of dimension 400x400:
  var pCanvas = PCanvas(400, 400, MyCanvasPainter());

  // The native canvas:
  var canvasNative = pCanvas.canvasNative as CanvasElement;

  // Allow the canvas to adjust to the parent dimension.
  // This will automatically adjust `PCanvas.width/height`:
  canvasNative.style
    ..width = '100%'
    ..height = 'calc(100% - 40px)';

  divOutput.append(canvasNative);

  // Download button:
  var btnDownload = ButtonElement()
    ..text = 'Download PNG'
    ..style.height = '20px'
    ..style.margin = '4px';

  divOutput.append(btnDownload);

  // Waite for canvas to load before attach a listener to the download button:
  await pCanvas.waitLoading();

  btnDownload.onClick.listen((_) => _downloadPNG(pCanvas));
}

/// Download the [pCanvas] as a PNG.
Future<void> _downloadPNG(PCanvas pCanvas) async {
  var png = await pCanvas.toPNG();

  var blob = Blob([png], 'image/png');
  var pngUrl = Url.createObjectUrlFromBlob(blob);

  var a = AnchorElement(href: pngUrl)..download = 'pcanvas.png';

  a.click();
}

/// The [PCanvas] painter implementation.
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

  int rectX = 10;
  int rectY = 10;
  PColor rectColor = PColor.colorRed.copyWith(alpha: 0.30);

  @override
  bool paint(PCanvas pCanvas) {
    // Clear the canvas with `colorGrey`:
    pCanvas.clear(style: PStyle(color: PColor.colorGrey));

    var canvasWidth = pCanvas.width;
    var canvasHeight = pCanvas.height;

    var canvasWidthHalf = canvasWidth ~/ 2;
    var canvasHeightHalf = canvasHeight ~/ 2;

    // Draw an image fitting the target area:
    pCanvas.drawImageFitted(img1, 0, 0, canvasWidthHalf, canvasHeight);

    // Draw an image centered at `area` with scale `0.3`:
    pCanvas.centered(
      area: PRectangle(0, 0, canvasWidthHalf, canvasHeight * 0.50),
      dimension: img2.dimension,
      scale: 0.3,
      (pc, p, sz) => pc.drawImageScaled(img2, p.x, p.y, sz.width, sz.height),
    );

    // Fill a rectangle at ($rectX,$rectY):
    pCanvas.fillRect(rectX, rectY, 20, 20, PStyle(color: rectColor));

    // Fill a rectangle at (40,10):
    pCanvas.fillRect(40, 10, 20, 20, PStyle(color: PColor.colorGreen));

    var fontPR = PFont('Arial', 24);
    var textPR = 'devicePixelRatio: ${pCanvas.devicePixelRatio}';

    // Measure `text`:
    var m = pCanvas.measureText(textPR, fontPR);

    // Draw `text` at (10,55):
    pCanvas.drawText(textPR, 10, 55, fontPR, PStyle(color: PColor.colorBlack));

    // Stroke a rectangle around the `text`:
    pCanvas.strokeRect(10 - 2, 55 - 2, m.actualWidth + 4, m.actualHeight + 4,
        PStyle(color: PColor.colorYellow));

    var fontHello = PFont('Arial', 48);
    var textHello = 'Hello World!';

    // Draw a text and a shadow at the center of `area`:
    pCanvas.centered(
      area: PRectangle(0, 0, canvasWidthHalf, canvasHeight * 0.30),
      dimension: pCanvas.measureText(textHello, fontHello),
      (pc, p, sz) {
        pc.drawText(textHello, p.x + 4, p.y + 4, fontHello,
            PStyle(color: PColorRGBA(0, 0, 0, 0.30)));
        pc.drawText(
            textHello, p.x, p.y, fontHello, PStyle(color: PColor.colorBlue));
      },
    );

    var path = [100, 10, const Point(130, 25), 100, 40];

    // Stroke a `path`:
    pCanvas.strokePath(path, PStyle(color: PColor.colorRed, size: 3),
        closePath: true);

    // Fill the right side of the canvas with a linear gradient:
    pCanvas.fillRightLeftGradient(canvasWidthHalf, 0, canvasWidthHalf,
        canvasHeight, PColorRGB(0, 32, 94), PColor.colorBlack);

    // Fill a circle:
    pCanvas.fillCircle(canvasWidthHalf + (canvasWidthHalf ~/ 2),
        canvasHeightHalf, 20, PStyle(color: PColor.colorGreen));

    return true;
  }

  /// Receives canvas clicks:
  @override
  void onClick(PCanvasEvent event) {
    rectColor = rectColor.copyWith(r: 0, b: 255);

    rectX += 10;
    rectY += 10;

    // Force a refresh of the canvas:
    refresh();
  }
}
