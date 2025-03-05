import 'pcanvas_base.dart';
import 'pcanvas_web.dart';

class PCanvasFactoryWeb extends PCanvasFactory {
  static final PCanvasFactoryWeb instance = PCanvasFactoryWeb._();

  PCanvasFactoryWeb._() : super.impl();

  @override
  PCanvas createPCanvas(int width, int height, PCanvasPainter painter,
          {PCanvasPixels? initialPixels}) =>
      PCanvasHTML(width, height, painter, initialPixels: initialPixels);
}

PCanvasFactory createPCanvasFactoryImpl() => PCanvasFactoryWeb.instance;
