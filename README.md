# pcanvas

[![pub package](https://img.shields.io/pub/v/pcanvas.svg?logo=dart&logoColor=00b9fc)](https://pub.dev/packages/pcanvas)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![CI](https://img.shields.io/github/workflow/status/gmpassos/pcanvas/Dart%20CI/master?logo=github-actions&logoColor=white)](https://github.com/gmpassos/pcanvas/actions)
[![GitHub Tag](https://img.shields.io/github/v/tag/gmpassos/pcanvas?logo=git&logoColor=white)](https://github.com/gmpassos/pcanvas/releases)
[![New Commits](https://img.shields.io/github/commits-since/gmpassos/pcanvas/latest?logo=git&logoColor=white)](https://github.com/gmpassos/pcanvas/network)
[![Last Commits](https://img.shields.io/github/last-commit/gmpassos/pcanvas?logo=git&logoColor=white)](https://github.com/gmpassos/pcanvas/commits/master)
[![Pull Requests](https://img.shields.io/github/issues-pr/gmpassos/pcanvas?logo=github&logoColor=white)](https://github.com/gmpassos/pcanvas/pulls)
[![Code size](https://img.shields.io/github/languages/code-size/gmpassos/pcanvas?logo=github&logoColor=white)](https://github.com/gmpassos/pcanvas)
[![License](https://img.shields.io/github/license/gmpassos/pcanvas?logo=open-source-initiative&logoColor=green)](https://github.com/gmpassos/pcanvas/blob/master/LICENSE)

A portable canvas that can work in many platforms (Flutter, Web, Desktop, in-memory Image).

## Motivation

Canvas operations can be highly dependent to the platform of the canvas framework. The main idea of this package is to allow
the same behavior in multiple platforms and also improve performance and ease of use.

## Platform Implementations

When a `PCanvas` instance is created it will choose the proper
implementation for the platform:

- `PCanvasBitmap`:
  - In-memory bitmap as canvas.

- `PCanvasHTML`:
  - Web (`dart:html`) canvas using `CanvasElement`.

- `PCanvasFlutter`:
  - Flutter (`dart:ui`) canvas using a `CustomPainter`.
  - Widget: `PCanvasWidget`.
  - Package: [pcanvas_flutter][pcanvas_flutter]

[pcanvas_flutter]: https://pub.dev/packages/pcanvas_flutter

## Usage

```dart
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

  // Convert the canvas to a PNG:
  var pngData = await pCanvas.toPNG();
  
  //...
}

class MyCanvasPainter extends PCanvasPainter {
  late PCanvasImage img1;
  
  @override
  Future<bool> loadResources(PCanvas pCanvas) async {
    var img1URL = 'https://i.postimg.cc/k5TnC1H9/land-scape-1.jpg';
  
    pCanvas.log('** Loading image...');
    img1 = pCanvas.createCanvasImage(img1URL);

    await img1.load();
    pCanvas.log('** Image loaded: $img1');

    return true;
  }

  @override
  bool paint(PCanvas pCanvas) {
    // Clear the canvas with `colorGrey`:
    pCanvas.clear(style: PStyle(color: PColor.colorGrey));

    // Draw an image fitting the target area:
    pCanvas.drawImageFitted(img1, 0, 0, pCanvas.width ~/ 2, pCanvas.height);
    
    // Fill a rectangle at (10,10):
    pCanvas.fillRect(
        10, 10, 20, 20, PStyle(color: PColor.colorRed.copyWith(alpha: 0.30)));

    // Fill a rectangle at (40,10):
    pCanvas.fillRect(40, 10, 20, 20, PStyle(color: PColor.colorGreen));

    var font = PFont('Arial', 14);
    var text = 'Canvas pixelRatio: ${pCanvas.pixelRatio}';

    // Measure `text`:
    var m = pCanvas.measureText(text, font);

    // Draw `text` at (10,55):
    pCanvas.drawText(text, 10, 55, font, PStyle(color: PColor.colorBlack));

    // Stroke a rectangle around the `text`:
    pCanvas.strokeRect(10 - 2, 55 - 2, m.actualWidth + 4, m.actualHeight + 4,
        PStyle(color: PColor.colorYellow));

    // Stroke a `path`:
    pCanvas.strokePath([100, 10, 130, 25, 100, 40], PStyle(color: PColor.colorRed, size: 3),
        closePath: true);

    return true;
  }
}
```

## Examples

See the usage examples at:

- https://github.com/gmpassos/pcanvas/tree/master/example

## pcanvas_flutter

To use `PCanvas` with Flutter you need
the package [pcanvas_flutter][pcanvas_flutter],
where you can use the `PCanvasWidget` to build your UI.

GitHub project:
- https://github.com/gmpassos/pcanvas_flutter

## Source

The official source code is [hosted @ GitHub][github_pcanvas]:

- https://github.com/gmpassos/pcanvas

[github_pcanvas]: https://github.com/gmpassos/pcanvas

# Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

# Contribution

Any help from the open-source community is always welcome and needed:
- Found an issue?
    - Please fill a bug report with details.
- Wish a feature?
    - Open a feature request with use cases.
- Are you using and liking the project?
    - Promote the project: create an article, do a post or make a donation.
- Are you a developer?
    - Fix a bug and send a pull request.
    - Implement a new feature.
    - Improve the Unit Tests.
- Have you already helped in any way?
    - **Many thanks from me, the contributors and everybody that uses this project!**

*If you donate 1 hour of your time, you can contribute a lot,
because others will do the same, just be part and start with your 1 hour.*

[tracker]: https://github.com/gmpassos/pcanvas/issues

# Author

Graciliano M. Passos: [gmpassos@GitHub][github].

[github]: https://github.com/gmpassos

## License

[Apache License - Version 2.0][apache_license]

[apache_license]: https://www.apache.org/licenses/LICENSE-2.0.txt
