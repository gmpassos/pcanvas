import 'pcanvas_base.dart';
import 'pcanvas_html.dart';

class PCanvasFactoryHTML extends PCanvasFactory {
  static final PCanvasFactoryHTML instance = PCanvasFactoryHTML._();

  PCanvasFactoryHTML._() : super.impl();

  @override
  PCanvas createPCanvas(int width, int height, PCanvasPainter painter,
          {PCanvasPixels? initialPixels}) =>
      PCanvasHTML(width, height, painter, initialPixels: initialPixels);
}

PCanvasFactory createPCanvasFactoryImpl() => PCanvasFactoryHTML.instance;
