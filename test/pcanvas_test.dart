import 'dart:async';
import 'dart:typed_data';

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

    test('PCanvas.pixels', () async {
      var pCanvas = PCanvas(3, 3, MyPainterChannels());

      print(pCanvas);

      print(
          'Endian.host: ${Endian.host == Endian.big ? 'big' : 'little'}-endian');

      await pCanvas.waitLoading();
      await pCanvas.callPainter();

      expect(pCanvas.painter.isLoadingResources, isFalse);

      expect(pCanvas.width, equals(3));
      expect(pCanvas.height, equals(3));

      print(pCanvas.toDataUrl());

      var pixels = await pCanvas.pixels;

      print(pixels);

      expect(pixels.length, equals(3 * 3));

      {
        var c = pixels.pixelColor(0, 0);
        expect(c.r, equals(1));
        expect(c.g, equals(2));
        expect(c.b, equals(3));
        expect(c.a, equals(255));
      }
    });

    void testPixelsFlood(PCanvasPixels pixels, PColor color) {
      var p = pixels.pixelColor(0, 0);
      var c = pixels.formatColor(color);
      var dataUrl = pixels.toDataUrl();

      expect(
          pixels.pixels, equals(List.filled(pixels.width * pixels.height, c)),
          reason: "$p != $color >> $dataUrl");
    }

    Future<void> testCanvasPixelsFlood(
        PCanvasPainter painter, PColor color) async {
      var pCanvas = PCanvas(3, 3, painter);

      print(pCanvas);

      await pCanvas.waitLoading();
      await pCanvas.callPainter();

      expect(pCanvas.painter.isLoadingResources, isFalse);

      expect(pCanvas.width, equals(3));
      expect(pCanvas.height, equals(3));

      print(pCanvas.toDataUrl());

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
        PCanvasPainter painter, PColor color, String title) async {
      var pCanvas = PCanvas(3, 3, painter);

      print(pCanvas);

      await pCanvas.waitLoading();
      await pCanvas.callPainter();

      expect(pCanvas.painter.isLoadingResources, isFalse);

      expect(pCanvas.width, equals(3));
      expect(pCanvas.height, equals(3));

      await _checkDataUrl(pCanvas, title);

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

    test(
        'pixelsRect[red]',
        () => testCanvasPixelsRect(
            MyPainterFillRectRed(), PColor.colorRed, 'pixelsRect[red]'));

    test(
        'pixelsRect[blue]',
        () => testCanvasPixelsRect(
            MyPainterFillRectBlue(), PColor.colorBlue, 'pixelsRect[blue]'));

    test('Gradient (top-down)', () async {
      var pCanvas = PCanvas(10, 100, MyPainterGradient1());

      print(pCanvas);

      await pCanvas.waitLoading();
      await pCanvas.callPainter();

      expect(pCanvas.painter.isLoadingResources, isFalse);

      expect(pCanvas.width, equals(10));
      expect(pCanvas.height, equals(100));

      await _checkDataUrl(pCanvas, 'Gradient (top-down)');

      var pixels = await pCanvas.pixels;
      print(pixels);

      print(await pixels.toDataUrl());

      expect(pixels.length, equals(10 * 100));

      final dpr = 1;

      expectPixel(pixels, x: 0, y: 0, t: 3, dpr: dpr);

      expectPixel(pixels, x: 2, y: 0, t: 3, dpr: dpr);

      expectPixel(pixels, x: 0, y: 99, r: 255, g: 255, b: 255, t: 3, dpr: dpr);

      expectPixel(pixels, x: 2, y: 99, r: 255, g: 255, b: 255, t: 3, dpr: dpr);
    });

    test('Gradient (left-right)', () async {
      var pCanvas = PCanvas(512, 3, MyPainterGradient2());

      print(pCanvas);

      await pCanvas.waitLoading();
      await pCanvas.callPainter();

      expect(pCanvas.painter.isLoadingResources, isFalse);

      expect(pCanvas.width, equals(512));
      expect(pCanvas.height, equals(3));

      await _checkDataUrl(pCanvas, 'Gradient (left-right)');

      var pixels = await pCanvas.pixels;
      print(pixels);

      expect(pixels.length, equals(3 * 512));

      // Full background won't be affected by devicePixelRatio.
      final dpr = 1;

      expectPixel(pixels, x: 0, y: 0, t: 3, dpr: dpr);

      expectPixel(pixels, x: 0, y: 2, t: 3, dpr: dpr);

      expectPixel(pixels, x: 511, y: 0, r: 255, g: 255, b: 255, t: 3, dpr: dpr);

      expectPixel(pixels, x: 511, y: 2, r: 255, g: 255, b: 255, t: 3, dpr: dpr);
    });

    test('Text', () async {
      var pCanvas = PCanvas(30, 15, MyPainterText1());

      print(pCanvas);

      await pCanvas.waitLoading();
      await pCanvas.callPainter();

      expect(pCanvas.painter.isLoadingResources, isFalse);

      expect(pCanvas.width, equals(30));
      expect(pCanvas.height, equals(15));

      await _checkDataUrl(pCanvas, 'Text');

      var pixels = await pCanvas.pixels;
      print(pixels);

      expect(pixels.length, equals(30 * 15));

      var dpr = pCanvas.devicePixelRatio;

      expectPixel(pixels, x: 0, y: 0, r: 255, g: 255, b: 255, t: 50, dpr: dpr);

      expectPixel(pixels, x: 2, y: 2, r: 255, t: 128, tR: 50, dpr: dpr);

      expectPixel(pixels, x: 1, y: 5, r: 255, g: 255, b: 255, t: 50, dpr: dpr);
    });

    test('FillRect3', () async {
      var pCanvas = PCanvas(10, 10, MyPainterFillRect3());

      print(pCanvas);

      await pCanvas.waitLoading();
      await pCanvas.callPainter();

      expect(pCanvas.painter.isLoadingResources, isFalse);

      expect(pCanvas.width, equals(10));
      expect(pCanvas.height, equals(10));

      await _checkDataUrl(pCanvas, 'FillRect3');

      var pixels = await pCanvas.pixels;
      print(pixels);

      expect(pixels.length, equals(10 * 10));

      final dpr = 1;

      expectPixel(pixels, x: 0, y: 0, t: 40, dpr: dpr);
      expectPixel(pixels, x: 9, y: 0, t: 40, dpr: dpr);
      expectPixel(pixels, x: 0, y: 9, t: 40, dpr: dpr);
      expectPixel(pixels, x: 9, y: 9, t: 40, dpr: dpr);

      expectPixel(pixels, x: 2, y: 2, t: 1, dpr: dpr);
      expectPixel(pixels, x: 7, y: 2, t: 1, dpr: dpr);
      expectPixel(pixels, x: 7, y: 7, t: 1, dpr: dpr);
      expectPixel(pixels, x: 2, y: 7, t: 1, dpr: dpr);

      expectPixel(pixels, x: 3, y: 3, r: 255, t: 1, dpr: dpr);
      expectPixel(pixels, x: 3 + 3, y: 3, r: 255, t: 1, dpr: dpr);
      expectPixel(pixels, x: 3 + 3, y: 3 + 3, r: 255, t: 1, dpr: dpr);
      expectPixel(pixels, x: 3, y: 3 + 3, r: 255, t: 1, dpr: dpr);

      expectPixel(pixels, x: 3 + 2, y: 3 + 2, r: 255, t: 1, dpr: dpr);
    });

    test('StrokeRect1', () async {
      var pCanvas = PCanvas(10, 10, MyPainterStrokeRect1());

      print(pCanvas);

      await pCanvas.waitLoading();
      await pCanvas.callPainter();

      expect(pCanvas.painter.isLoadingResources, isFalse);

      expect(pCanvas.width, equals(10));
      expect(pCanvas.height, equals(10));

      await _checkDataUrl(pCanvas, 'StrokeRect1');

      var pixels = await pCanvas.pixels;
      print(pixels);

      expect(pixels.length, equals(10 * 10));

      final dpr = 1;

      expectPixel(pixels, x: 0, y: 0, t: 40, dpr: dpr);
      expectPixel(pixels, x: 9, y: 0, t: 40, dpr: dpr);
      expectPixel(pixels, x: 0, y: 9, t: 40, dpr: dpr);
      expectPixel(pixels, x: 9, y: 9, t: 40, dpr: dpr);

      expectPixel(pixels, x: 2, y: 2, t: 1, dpr: dpr);
      expectPixel(pixels, x: 7, y: 2, t: 1, dpr: dpr);
      expectPixel(pixels, x: 7, y: 7, t: 1, dpr: dpr);
      expectPixel(pixels, x: 2, y: 7, t: 1, dpr: dpr);

      expectPixel(pixels, x: 3, y: 3, r: 255, t: 1, dpr: dpr);
      expectPixel(pixels, x: 3 + 3, y: 3, r: 255, t: 1, dpr: dpr);
      expectPixel(pixels, x: 3 + 3, y: 3 + 3, r: 255, t: 1, dpr: dpr);
      expectPixel(pixels, x: 3, y: 3 + 3, r: 255, t: 1, dpr: dpr);

      expectPixel(pixels, x: 3 + 1, y: 3 + 1, t: 1, dpr: dpr);
      expectPixel(pixels, x: 3 + 2, y: 3 + 1, t: 1, dpr: dpr);
      expectPixel(pixels, x: 3 + 2, y: 3 + 2, t: 1, dpr: dpr);
      expectPixel(pixels, x: 3 + 1, y: 3 + 2, t: 1, dpr: dpr);

      expectPixel(pixels, x: 3 + 2, y: 3 + 2, t: 1, dpr: dpr);
    });

    test('StrokeRect2', () async {
      var pCanvas = PCanvas(10, 10, MyPainterStrokeRect2());

      print(pCanvas);

      await pCanvas.waitLoading();
      await pCanvas.callPainter();

      expect(pCanvas.painter.isLoadingResources, isFalse);

      expect(pCanvas.width, equals(10));
      expect(pCanvas.height, equals(10));

      await _checkDataUrl(pCanvas, 'Rect4');

      var pixels = await pCanvas.pixels;
      print(pixels);

      expect(pixels.length, equals(10 * 10));

      final dpr = 1;

      expectPixel(pixels, x: 0, y: 0, t: 40, dpr: dpr);
      expectPixel(pixels, x: 9, y: 0, t: 40, dpr: dpr);
      expectPixel(pixels, x: 0, y: 9, t: 40, dpr: dpr);
      expectPixel(pixels, x: 9, y: 9, t: 40, dpr: dpr);

      expectPixel(pixels, x: 1, y: 1, t: 1, dpr: dpr);
      expectPixel(pixels, x: 8, y: 1, t: 1, dpr: dpr);
      expectPixel(pixels, x: 8, y: 8, t: 1, dpr: dpr);
      expectPixel(pixels, x: 1, y: 8, t: 1, dpr: dpr);

      expectPixel(pixels, x: 3, y: 3, r: 255, t: 1, dpr: dpr);
      expectPixel(pixels, x: 3 + 3, y: 3, r: 255, t: 1, dpr: dpr);
      expectPixel(pixels, x: 3 + 3, y: 3 + 3, r: 255, t: 1, dpr: dpr);
      expectPixel(pixels, x: 3, y: 3 + 3, r: 255, t: 1, dpr: dpr);

      expectPixel(pixels, x: 3 - 1, y: 3 - 1, r: 255, t: 1, dpr: dpr);
      expectPixel(pixels, x: 3 + 4, y: 3 - 1, r: 255, t: 1, dpr: dpr);
      expectPixel(pixels, x: 3 + 4, y: 3 + 4, r: 255, t: 1, dpr: dpr);
      expectPixel(pixels, x: 3 - 1, y: 3 + 4, r: 255, t: 1, dpr: dpr);

      expectPixel(pixels, x: 3 + 2, y: 3 + 2, t: 1, dpr: dpr);
      expectPixel(pixels, x: 3 + 2, y: 3 + 1, t: 1, dpr: dpr);
      expectPixel(pixels, x: 3 + 2, y: 3 + 2, t: 1, dpr: dpr);
      expectPixel(pixels, x: 3 + 1, y: 3 + 2, t: 1, dpr: dpr);

      expectPixel(pixels, x: 3 + 2, y: 3 + 2, t: 1, dpr: dpr);
    });

    test('StrokeRect3', () async {
      var pCanvas = PCanvas(10, 10, MyPainterStrokeRect3());

      print(pCanvas);

      await pCanvas.waitLoading();
      await pCanvas.callPainter();

      expect(pCanvas.painter.isLoadingResources, isFalse);

      expect(pCanvas.width, equals(10));
      expect(pCanvas.height, equals(10));

      await _checkDataUrl(pCanvas, 'StrokeRect3');

      var pixels = await pCanvas.pixels;
      print(pixels);

      expect(pixels.length, equals(10 * 10));

      final dpr = 1;

      expectPixel(pixels, x: 0, y: 0, t: 40, dpr: dpr);
      expectPixel(pixels, x: 9, y: 0, t: 40, dpr: dpr);
      expectPixel(pixels, x: 0, y: 9, t: 40, dpr: dpr);
      expectPixel(pixels, x: 9, y: 9, t: 40, dpr: dpr);

      expectPixel(pixels, x: 1, y: 1, t: 1, dpr: dpr);
      expectPixel(pixels, x: 9, y: 1, t: 1, dpr: dpr);
      expectPixel(pixels, x: 9, y: 9, t: 1, dpr: dpr);
      expectPixel(pixels, x: 1, y: 9, t: 1, dpr: dpr);

      expectPixel(pixels, x: 3, y: 3, r: 255, t: 1, dpr: dpr);
      expectPixel(pixels, x: 3 + 3, y: 3, r: 255, t: 1, dpr: dpr);
      expectPixel(pixels, x: 3 + 3, y: 3 + 3, r: 255, t: 1, dpr: dpr);
      expectPixel(pixels, x: 3, y: 3 + 3, r: 255, t: 1, dpr: dpr);

      expectPixel(pixels, x: 3 - 1, y: 3 - 1, r: 255, t: 1, dpr: dpr);
      expectPixel(pixels, x: 3 + 5, y: 3 - 1, r: 255, t: 1, dpr: dpr);
      expectPixel(pixels, x: 3 + 5, y: 3 + 5, r: 255, t: 1, dpr: dpr);
      expectPixel(pixels, x: 3 - 1, y: 3 + 5, r: 255, t: 1, dpr: dpr);

      expectPixel(pixels, x: 3 + 2, y: 3 + 2, t: 1, dpr: dpr);
      expectPixel(pixels, x: 3 + 5 + 1, y: 3 - 2, t: 1, dpr: dpr);
      expectPixel(pixels, x: 3 + 5 + 1, y: 3 + 2, t: 1, dpr: dpr);
      expectPixel(pixels, x: 3 - 2, y: 3 + 1, t: 1, dpr: dpr);

      expectPixel(pixels, x: 3 + 5 - 3, y: 3 + 5 - 3, t: 1, dpr: dpr);
    });

    test('Circle1', () async {
      var pCanvas = PCanvas(10, 10, MyPainterCircle1());

      print(pCanvas);

      await pCanvas.waitLoading();
      await pCanvas.callPainter();

      expect(pCanvas.painter.isLoadingResources, isFalse);

      expect(pCanvas.width, equals(10));
      expect(pCanvas.height, equals(10));

      await _checkDataUrl(pCanvas, 'Circle1');

      var pixels = await pCanvas.pixels;
      print(pixels);

      expect(pixels.length, equals(10 * 10));

      final dpr = 1;

      expectPixel(pixels, x: 0, y: 0, t: 40, dpr: dpr);
      expectPixel(pixels, x: 9, y: 0, t: 40, dpr: dpr);
      expectPixel(pixels, x: 0, y: 9, t: 40, dpr: dpr);
      expectPixel(pixels, x: 9, y: 9, t: 40, dpr: dpr);

      expectPixel(pixels, x: 5 - 4, y: 5, t: 1, dpr: dpr);
      expectPixel(pixels, x: 5 + 4, y: 5, t: 1, dpr: dpr);
      expectPixel(pixels, x: 5, y: 5 - 4, t: 1, dpr: dpr);
      expectPixel(pixels, x: 5, y: 5 + 4, t: 1, dpr: dpr);

      expectPixel(pixels, x: 5, y: 5, r: 255, t: 40, dpr: dpr);

      expectPixel(pixels, x: 5 - 2, y: 5, r: 255, t: 40, dpr: dpr);
      expectPixel(pixels, x: 5 + 2, y: 5, r: 255, t: 40, dpr: dpr);
      expectPixel(pixels, x: 5, y: 5 - 2, r: 255, t: 40, dpr: dpr);
      expectPixel(pixels, x: 5, y: 5 + 2, r: 255, t: 40, dpr: dpr);
    });

    test('PCanvasPanel2D', () async {
      var pCanvas = PCanvas(100, 50, MyPainterFlood2());

      print(pCanvas);

      var panel1 = PCanvasPanel2D(
          x: 4,
          y: 8,
          width: 20,
          height: 10,
          style: PColor.colorGreen.toStyle());

      var rect1 = PRectangleElement(
          x: 2, y: 2, width: 8, height: 4, style: PColor.colorRed.toStyle());

      panel1.addElement(rect1);

      pCanvas.addElement(panel1);

      await pCanvas.waitLoading();
      await pCanvas.callPainter();

      expect(pCanvas.painter.isLoadingResources, isFalse);

      expect(pCanvas.width, equals(100));
      expect(pCanvas.height, equals(50));

      await _checkDataUrl(pCanvas, 'PCanvasPanel2D');

      var pixels = await pCanvas.pixels;
      print(pixels);

      expect(pixels.length, equals(100 * 50));

      final dpr = 1;

      expectPixel(pixels, x: 0, y: 0, b: 255, t: 1, dpr: dpr);

      expectPixel(pixels, x: 3, y: 9, b: 255, t: 1, dpr: dpr);

      expectPixel(pixels, x: 5, y: 9, g: 255, t: 1, dpr: dpr);

      expectPixel(pixels, x: 5, y: 11, g: 255, t: 1, dpr: dpr);

      expectPixel(pixels, x: 7, y: 11, r: 255, t: 1, dpr: dpr);

      expectPixel(pixels, x: 13, y: 11, r: 255, t: 1, dpr: dpr);

      expectPixel(pixels, x: 15, y: 11, g: 255, t: 1, dpr: dpr);
    });

    test('PCanvasPanel2D (clip)', () async {
      var pCanvas = PCanvas(100, 50, MyPainterFlood2());

      print(pCanvas);

      var panel1 = PCanvasPanel2D(
          x: 4,
          y: 8,
          width: 20,
          height: 10,
          style: PColor.colorGreen.toStyle());

      var rect1 = PRectangleElement(
          x: -2, y: 2, width: 8, height: 4, style: PColor.colorRed.toStyle());

      panel1.addElement(rect1);

      pCanvas.addElement(panel1);

      await pCanvas.waitLoading();
      await pCanvas.callPainter();

      expect(pCanvas.painter.isLoadingResources, isFalse);

      expect(pCanvas.width, equals(100));
      expect(pCanvas.height, equals(50));

      await _checkDataUrl(pCanvas, 'PCanvasPanel2D (clip)');

      var pixels = await pCanvas.pixels;
      print(pixels);

      expect(pixels.length, equals(100 * 50));

      final dpr = 1;

      expectPixel(pixels, x: 0, y: 0, b: 255, t: 1, dpr: dpr);

      expectPixel(pixels, x: 3, y: 9, b: 255, t: 1, dpr: dpr);

      expectPixel(pixels, x: 5, y: 9, g: 255, t: 1, dpr: dpr);

      expectPixel(pixels, x: 5, y: 11, r: 255, t: 1, dpr: dpr);

      expectPixel(pixels, x: 7, y: 11, r: 255, t: 1, dpr: dpr);

      expectPixel(pixels, x: 12, y: 11, g: 255, t: 1, dpr: dpr);

      expectPixel(pixels, x: 13, y: 11, g: 255, t: 1, dpr: dpr);
    });
  });
}

Future<void> _checkDataUrl(PCanvas pCanvas, String title) async {
  print('$title:');
  var dataUrl = await pCanvas.toDataUrl();
  print(dataUrl);
  expect(dataUrl, startsWith('data:image/png;base64,iV'));
}

class MyPainterChannels extends PCanvasPainter {
  @override
  FutureOr<bool> paint(PCanvas pCanvas) {
    pCanvas.clear(style: PStyle(color: PColorRGBA(01, 02, 03, 1)));
    return true;
  }
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

class MyPainterFillRectRed extends PCanvasPainter {
  @override
  FutureOr<bool> paint(PCanvas pCanvas) {
    pCanvas.clear(style: PStyle(color: PColor.colorBlack));

    pCanvas.fillRect(0, 0, 1, 3, PStyle(color: PColor.colorRed));

    return true;
  }
}

class MyPainterFillRectBlue extends PCanvasPainter {
  @override
  FutureOr<bool> paint(PCanvas pCanvas) {
    pCanvas.clear(style: PStyle(color: PColor.colorBlack));

    pCanvas.fillRect(0, 0, 1, 3, PStyle(color: PColor.colorBlue, size: 1));

    return true;
  }
}

class MyPainterFillRect3 extends PCanvasPainter {
  @override
  FutureOr<bool> paint(PCanvas pCanvas) {
    pCanvas.clear(style: PStyle(color: PColor.colorBlack));

    pCanvas.fillRect(3, 3, 4, 4, PStyle(color: PColor.colorRed, size: 1));

    return true;
  }
}

class MyPainterStrokeRect1 extends PCanvasPainter {
  @override
  FutureOr<bool> paint(PCanvas pCanvas) {
    pCanvas.clear(style: PStyle(color: PColor.colorBlack));

    pCanvas.strokeRect(3, 3, 4, 4, PStyle(color: PColor.colorRed, size: 1));

    return true;
  }
}

class MyPainterStrokeRect2 extends PCanvasPainter {
  @override
  FutureOr<bool> paint(PCanvas pCanvas) {
    pCanvas.clear(style: PStyle(color: PColor.colorBlack));

    pCanvas.strokeRect(3, 3, 4, 4, PStyle(color: PColor.colorRed, size: 2));

    return true;
  }
}

class MyPainterStrokeRect3 extends PCanvasPainter {
  @override
  FutureOr<bool> paint(PCanvas pCanvas) {
    pCanvas.clear(style: PStyle(color: PColor.colorBlack));

    pCanvas.strokeRect(3, 3, 5, 5, PStyle(color: PColor.colorRed, size: 3));

    return true;
  }
}

class MyPainterCircle1 extends PCanvasPainter {
  @override
  FutureOr<bool> paint(PCanvas pCanvas) {
    pCanvas.clear(style: PStyle(color: PColor.colorBlack));

    pCanvas.fillCircle(5, 5, 3, PStyle(color: PColor.colorRed, size: 1));

    return true;
  }
}

class MyPainterCircle2 extends PCanvasPainter {
  @override
  FutureOr<bool> paint(PCanvas pCanvas) {
    pCanvas.clear(style: PStyle(color: PColor.colorBlack));

    pCanvas.strokeCircle(5, 5, 2, PStyle(color: PColor.colorRed, size: 1));

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

void expectPixel(PCanvasPixels pixels,
    {required num x,
    required num y,
    int r = 0,
    int g = 0,
    int b = 0,
    double a = 1,
    required int t,
    int? tR,
    int? tG,
    int? tB,
    int? tA,
    // devicePixelRatio:
    required num? dpr}) {
  if (dpr != null) {
    x = x ~/ dpr;
    y = y ~/ dpr;
  }

  var pixel = pixels.pixelColor(x.toInt(), y.toInt());
  var expectedPixel = PColorRGBA(r, g, b, a);

  var dataUrl = pixels.toDataUrl();

  expect(pixel.maxDistance(expectedPixel), inInclusiveRange(0, t),
      reason:
          "($x,$y)/$dpr >> pixel:$pixel != expectedPixel:$expectedPixel >> tolerance: $t >> $dataUrl");

  if (tR != null) {
    expect(pixel.distanceR(expectedPixel), inInclusiveRange(0, tR),
        reason:
            "($x,$y)/$dpr >> pixel:$pixel !=(R) expectedPixel:$expectedPixel >> toleranceR: $tR >> $dataUrl");
  }

  if (tG != null) {
    expect(pixel.distanceG(expectedPixel), inInclusiveRange(0, tG),
        reason:
            "($x,$y)/$dpr >> pixel:$pixel !=(G) expectedPixel:$expectedPixel >> toleranceG: $tG >> $dataUrl");
  }

  if (tB != null) {
    expect(pixel.distanceB(expectedPixel), inInclusiveRange(0, tB),
        reason:
            "($x,$y)/$dpr >> pixel:$pixel !=(B) expectedPixel:$expectedPixel >> toleranceB: $tB >> $dataUrl");
  }

  if (tA != null) {
    expect(pixel.distanceA(expectedPixel), inInclusiveRange(0, tA),
        reason:
            "($x,$y)/$dpr >> pixel:$pixel !=(A) expectedPixel:$expectedPixel >> toleranceA: $tA >> $dataUrl");
  }
}
