## 1.1.2

- `PCanvasPainter`:
  - `refresh`: return `Future<bool>`.
  - `requestRepaint` and `requestRepaintDelayed`.

- sdk: '>=3.6.0 <4.0.0'

- collection: ^1.19.0
- dio: ^5.8.0+1
- image: ^4.5.3
- path_parsing: ^1.1.0
- xml: ^6.5.0

- lints: ^5.1.1
- test: ^1.25.15
- dependency_validator: ^5.0.2
- coverage: ^1.11.1

## 1.1.1

- `GShape`:
  - Added `scaled(double scale)`;

- collection: ^1.18.0
- dio: ^5.7.0
- image: ^4.3.0
- xml: ^6.4.2

- lints: ^3.0.0
- test: ^1.25.8
- dependency_validator: ^3.2.3
- coverage: ^1.10.0

## 1.1.0

- `PCanvasEvent`:
  - Added `preventDefault`
- `PCanvasClickEvent`:
  - Added `copyWith` and `copyWith`.
- `PCanvasKeyEvent`:
  - Added `copyWith`.

- `PColor`: added support to HSV.

- `PCanvasPainter`:
  - Added `onClickMove`.
  - Added `dispatchOnClick...` and `dispatchOnKey...`.

- Added `PCanvasCursor`.

- `PCanvas`:
  - Added `setCursor` and `getCursor`.
  - Added `requestRepaintDelayed`, `isPaintRequested`, `getElement` and `elementsLength`.
  - Added `onPaint`.
  - Added `preventEventDefault`.

- Added `DynamicDimension`, `DynamicPosition`

- Added `CubicCurveTo`.

- `PCanvasElement`:
  - Now implements `WithJson`.
  - Added `onClick...` and `onKey...`.

- Added `PCanvasGridPanel2D` and `PCanvasBackgroundGradient`.

- New `PGraphic`, `Graphic`, `GPanel`, `GRectangle`, `GLine`, `GSvg` and `GSVGPath`.

- `PCanvasHTML`:
  - Fix `checkDimension`: avoid a loop of dimension modifications and checks.
  - Fix `set subClip`.
  - `_drawPath`: add support to `CubicCurveTo` (used by `GSVG`).

- sdk: '>=3.0.0 <4.0.0'
- collection: ^1.17.1
- dio: ^5.1.2
- image: ^4.0.17
- path_parsing: ^1.0.1
- xml: ^6.3.0
- lints: ^2.1.0
- test: ^1.24.2
- coverage: ^1.6.3

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
