import 'dart:async';

import 'package:pcanvas/pcanvas.dart';
import 'package:test/test.dart';

void main() {
  group('PCanvas', () {
    test('PDimension', () {
      {
        var d = PDimension(10, 10);
        expect(d.dimension, equals(PDimension(10, 10)));
        expect(d.width, equals(10));
        expect(d.height, equals(10));
        expect(d.aspectRation, equals(1));
        expect(d.area, equals(100));
        expect(d.center, equals(Point(5, 5)));
        expect(d.isZeroDimension, isFalse);
      }
      {
        var d = PDimension(20, 10);
        expect(d.dimension, equals(PDimension(20, 10)));
        expect(d.width, equals(20));
        expect(d.height, equals(10));
        expect(d.aspectRation, equals(2));
        expect(d.area, equals(200));
        expect(d.center, equals(Point(10, 5)));
        expect(d.isZeroDimension, isFalse);
      }
      {
        var d = PDimension(10, 20);
        expect(d.dimension, equals(PDimension(10, 20)));
        expect(d.width, equals(10));
        expect(d.height, equals(20));
        expect(d.aspectRation, equals(0.5));
        expect(d.area, equals(200));
        expect(d.center, equals(Point(5, 10)));
        expect(d.isZeroDimension, isFalse);
      }
      {
        var d = PDimension(0, 10);
        expect(d.dimension, equals(d));
        expect(d.aspectRation, equals(0));
        expect(d.area, equals(0));
        expect(d.center, equals(Point(0, 5)));
        expect(d.isZeroDimension, isTrue);
      }
      {
        var d = PDimension(10, 0);
        expect(d.dimension, equals(d));
        expect(d.aspectRation, equals(0));
        expect(d.area, equals(0));
        expect(d.center, equals(Point(5, 0)));
        expect(d.isZeroDimension, isTrue);
      }
    });

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

    test('Gradient: top-down', () async {
      var pCanvas = PCanvas(3, 100, MyPainterGradient1());

      print(pCanvas);

      await pCanvas.waitLoading();
      pCanvas.callPainter();

      expect(pCanvas.painter.isLoadingResources, isFalse);

      expect(pCanvas.width, equals(3));
      expect(pCanvas.height, equals(100));

      var pixels = await pCanvas.pixels;

      print(pixels);

      expect(pixels.length, equals(3 * 100));

      expect(pixels.pixelColor(0, 0).maxDistance(PColorRGBA(0, 0, 0, 1)),
          inInclusiveRange(0, 3));

      expect(pixels.pixelColor(2, 0).maxDistance(PColorRGBA(0, 0, 0, 1)),
          inInclusiveRange(0, 3));

      expect(pixels.pixelColor(0, 99).maxDistance(PColorRGBA(255, 255, 255, 1)),
          inInclusiveRange(0, 3));

      expect(pixels.pixelColor(2, 99).maxDistance(PColorRGBA(255, 255, 255, 1)),
          inInclusiveRange(0, 3));
    });

    test('Gradient: left-right', () async {
      var pCanvas = PCanvas(512, 3, MyPainterGradient2());

      print(pCanvas);

      await pCanvas.waitLoading();
      pCanvas.callPainter();

      expect(pCanvas.painter.isLoadingResources, isFalse);

      expect(pCanvas.width, equals(512));
      expect(pCanvas.height, equals(3));

      var pixels = await pCanvas.pixels;

      print(pixels);

      expect(pixels.length, equals(3 * 512));

      expect(pixels.pixelColor(0, 0).maxDistance(PColorRGBA(0, 0, 0, 1)),
          inInclusiveRange(0, 3));

      expect(pixels.pixelColor(0, 2).maxDistance(PColorRGBA(0, 0, 0, 1)),
          inInclusiveRange(0, 3));

      expect(
          pixels.pixelColor(511, 0).maxDistance(PColorRGBA(255, 255, 255, 1)),
          inInclusiveRange(0, 3));

      expect(
          pixels.pixelColor(511, 2).maxDistance(PColorRGBA(255, 255, 255, 1)),
          inInclusiveRange(0, 3));
    });

    test('Text', () async {
      var pCanvas = PCanvas(30, 15, MyPainterText1());

      print(pCanvas);

      await pCanvas.waitLoading();
      pCanvas.callPainter();

      expect(pCanvas.painter.isLoadingResources, isFalse);

      expect(pCanvas.width, equals(30));
      expect(pCanvas.height, equals(15));

      var pixels = await pCanvas.pixels;

      print(pixels);

      expect(pixels.length, equals(30 * 15));

      expect(pixels.pixelColor(0, 0).maxDistance(PColorRGBA(255, 255, 255, 1)),
          inInclusiveRange(0, 30));

      expect(pixels.pixelColor(2, 2).maxDistance(PColorRGBA(255, 0, 0, 1)),
          inInclusiveRange(0, 30));

      expect(pixels.pixelColor(2, 6).maxDistance(PColorRGBA(255, 255, 255, 1)),
          inInclusiveRange(0, 30));

      expect(pixels.pixelColor(2, 8).maxDistance(PColorRGBA(255, 0, 0, 1)),
          inInclusiveRange(0, 30));
    });
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

class MyPainterGradient1 extends PCanvasPainter {
  @override
  FutureOr<bool> paint(PCanvas pCanvas) {
    pCanvas.fillTopDownGradient(0, 0, pCanvas.width, pCanvas.height,
        PColorRGB(0, 0, 0), PColorRGB(255, 255, 255));

    return true;
  }
}

class MyPainterGradient2 extends PCanvasPainter {
  @override
  FutureOr<bool> paint(PCanvas pCanvas) {
    pCanvas.fillLeftRightGradient(0, 0, pCanvas.width, pCanvas.height,
        PColorRGB(0, 0, 0), PColorRGB(255, 255, 255));

    return true;
  }
}

class MyPainterText1 extends PCanvasPainter {
  @override
  FutureOr<bool> paint(PCanvas pCanvas) {
    pCanvas.clear(style: PStyle(color: PColor.colorWhite));

    var font = PFont('Arial', 14);
    var text = 'X';
    var style = PStyle(color: PColor.colorRed);

    pCanvas.drawText(text, 0, 0, font, style);

    return true;
  }
}
