import 'dart:async';

import 'package:pcanvas/pcanvas.dart';
import 'package:test/test.dart';

void main() {
  group('PCanvas', () {
    void testPixelsFlood(PCanvasPixels pixels, PColor color) {
      var c = pixels.formatColor(color);
      expect(
          pixels.pixels, equals(List.filled(pixels.width * pixels.height, c)));
    }

    Future<void> testCanvasPixelsFlood(
        PCanvasPainter painter, PColor color) async {
      var pCanvas = PCanvas(3, 3, painter);

      print(pCanvas);

      await pCanvas.waitLoading();
      pCanvas.callPainter();

      expect(pCanvas.painter.isLoadingResources, isFalse);

      expect(pCanvas.width, equals(3));
      expect(pCanvas.height, equals(3));

      var pixels = await pCanvas.pixels;

      print(pixels);

      expect(pixels.length, equals(3 * 3));

      testPixelsFlood(pixels, color);

      {
        var pixelsRGBA = pixels.toPCanvasPixelsRGBA();
        testPixelsFlood(pixelsRGBA, color);

        testPixelsFlood(pixelsRGBA.toPCanvasPixelsRGBA(), color);
        testPixelsFlood(pixelsRGBA.toPCanvasPixelsARGB(), color);
        testPixelsFlood(pixelsRGBA.toPCanvasPixelsABGR(), color);
      }

      {
        var pixelsARGB = pixels.toPCanvasPixelsARGB();
        testPixelsFlood(pixelsARGB, color);

        testPixelsFlood(pixelsARGB.toPCanvasPixelsRGBA(), color);
        testPixelsFlood(pixelsARGB.toPCanvasPixelsARGB(), color);
        testPixelsFlood(pixelsARGB.toPCanvasPixelsABGR(), color);
      }

      {
        var pixelsABGR = pixels.toPCanvasPixelsABGR();
        testPixelsFlood(pixelsABGR, color);

        testPixelsFlood(pixelsABGR.toPCanvasPixelsRGBA(), color);
        testPixelsFlood(pixelsABGR.toPCanvasPixelsARGB(), color);
        testPixelsFlood(pixelsABGR.toPCanvasPixelsABGR(), color);
      }
    }

    test('pixelsFlood[red]',
        () => testCanvasPixelsFlood(MyPainterFlood1(), PColor.colorRed));

    test('pixelsFlood[blue]',
        () => testCanvasPixelsFlood(MyPainterFlood2(), PColor.colorBlue));

    void testPixelsRect(PCanvasPixels pixels, PColor color) {
      var bg = pixels.formatColor(PColor.colorBlack);
      var c = pixels.formatColor(color);

      var data1 = List.filled(pixels.width * pixels.height, bg);
      {
        data1[0] = c;

        data1[3] = c;

        data1[6] = c;
      }

      var data2 = List.filled(pixels.width * pixels.height, bg);
      {
        data2[0] = c;
        data2[1] = c;

        data2[3] = c;
        data2[4] = c;

        data2[6] = c;
        data2[7] = c;
      }

      expect(pixels.pixels, anyOf(equals(data1), equals(data2)));
    }

    Future<void> testCanvasPixelsRect(
        PCanvasPainter painter, PColor color) async {
      var pCanvas = PCanvas(3, 3, painter);

      print(pCanvas);

      await pCanvas.waitLoading();
      pCanvas.callPainter();

      expect(pCanvas.painter.isLoadingResources, isFalse);

      expect(pCanvas.width, equals(3));
      expect(pCanvas.height, equals(3));

      var pixels = await pCanvas.pixels;

      print(pixels);

      expect(pixels.length, equals(3 * 3));

      testPixelsRect(pixels, color);

      {
        var pixelsRGBA = pixels.toPCanvasPixelsRGBA();
        testPixelsRect(pixelsRGBA, color);

        testPixelsRect(pixelsRGBA.toPCanvasPixelsRGBA(), color);
        testPixelsRect(pixelsRGBA.toPCanvasPixelsARGB(), color);
        testPixelsRect(pixelsRGBA.toPCanvasPixelsABGR(), color);
      }

      {
        var pixelsARGB = pixels.toPCanvasPixelsARGB();
        testPixelsRect(pixelsARGB, color);

        testPixelsRect(pixelsARGB.toPCanvasPixelsRGBA(), color);
        testPixelsRect(pixelsARGB.toPCanvasPixelsARGB(), color);
        testPixelsRect(pixelsARGB.toPCanvasPixelsABGR(), color);
      }

      {
        var pixelsABGR = pixels.toPCanvasPixelsABGR();
        testPixelsRect(pixelsABGR, color);

        testPixelsRect(pixelsABGR.toPCanvasPixelsRGBA(), color);
        testPixelsRect(pixelsABGR.toPCanvasPixelsARGB(), color);
        testPixelsRect(pixelsABGR.toPCanvasPixelsABGR(), color);
      }
    }

    test('pixelsRect[red]',
        () => testCanvasPixelsRect(MyPainterRect1(), PColor.colorRed));

    test('pixelsRect[blue]',
        () => testCanvasPixelsRect(MyPainterRect2(), PColor.colorBlue));
  });
}

class MyPainterFlood1 extends PCanvasPainter {
  @override
  FutureOr<bool> paint(PCanvas pCanvas) {
    pCanvas.clear(style: PStyle(color: PColor.colorRed));
    return true;
  }
}

class MyPainterFlood2 extends PCanvasPainter {
  @override
  FutureOr<bool> paint(PCanvas pCanvas) {
    pCanvas.clear(style: PStyle(color: PColor.colorBlue));
    return true;
  }
}

class MyPainterRect1 extends PCanvasPainter {
  @override
  FutureOr<bool> paint(PCanvas pCanvas) {
    pCanvas.clear(style: PStyle(color: PColor.colorBlack));

    pCanvas.fillRect(0, 0, 1, 3, PStyle(color: PColor.colorRed));

    return true;
  }
}

class MyPainterRect2 extends PCanvasPainter {
  @override
  FutureOr<bool> paint(PCanvas pCanvas) {
    pCanvas.clear(style: PStyle(color: PColor.colorBlack));

    pCanvas.fillRect(0, 0, 1, 3, PStyle(color: PColor.colorBlue, size: 1));

    return true;
  }
}
