## 1.0.7

- `PCanvasPainter`:
  - Added `zIndex` to define the painter layer. Previously was fixed to `0`.
- Added `PCanvasFactory`:
  - Allows extra platform dependent implementations:
    - `pixelsToPNG` and `pixelsToDataUrl`
- `PCanvasBitmap.toPNG`:
  - Ensure `singleFrame: true`

## 1.0.6

- `PCanvas`:
  - Constructor: added parameter `initialPixels`. 
  - Added method `setPixels`.
  - Added support for `clip` and `subClip`.
  - Added `transform`: new `PcanvasTransform` class.
  - Added `saveState`, `restoreState` and `callWithGuardedState`.
  - `elements` now is unmmodifiable.
- `PCanvasPixels`:
  - New constructor `PCanvasPixels.fromBytes`.
  - Added `setPixel`, `setPixelFrom`, `setPixelsLineFrom`, `setPixelsColumnFrom` and `setPixelsRectFrom`.
  - Added `putPixels`, `copyRectangle` and `copyRect`.
  - Added `toPCanvas`, `toPNG` and `toDataUrl`.
- New `PCanvasElementContainer`:
  - New `PCanvasPanel2D` and `PRectangleElement`.
- `PRectangle`:
  - Added `intersectsRectangle`, `intersects` and `intersection`.
  - Added `containsRectangle`, `contains`, `containsPoint` and `containsXY`.
  - Added `transform`.
- image: ^4.0.7
- test: ^1.22.1
- collection: ^1.16.0

## 1.0.5

- Add support to stroke/fill circles.

## 1.0.4

- `PCanvasBitmap`:
  - Support for `bold` and `italic`.
  - Enable text anti-aliasing.

## 1.0.3

- Fix `PColorRGB.a`.

## 1.0.2

- `PCanvasEvent` now is abstract:
  - `PCanvasClickEvent`: for mouse and touch events.
  - `PCanvasKeyEvent`: for keyboatd events.
- `PCanvasPainter`:
  - Added support to key events
- `PCanvas`:
  - Added support to fill gradient operations.
- Added `PCanvasElement`
  - Base class for personalized canvas elements. 

## 1.0.1

- Added interface `WithDimension` to `PDimension` and `PCanvas`.
- Added `PCanvas.info`.
- README.md: added usage example.

## 1.0.0

- Initial version.
