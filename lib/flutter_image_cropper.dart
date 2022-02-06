import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_cropper/crop_image.dart';

import 'controller/crop_controller.dart';
import 'utilities/crop_grid.dart';

/// Widget to crop images.
///
/// See also:
///
///  * [CropController] to control the functioning of this widget.
class CropImage extends StatefulWidget {
  /// Controls the crop values being applied.
  ///
  /// If null, this widget will create its own [CropController]. If you want to specify initial values of
  /// [aspectRatio] or [defaultCrop], you need to use your own [CropController].
  /// Otherwise, [aspectRatio] will not be enforced and the [defaultCrop] will be the full image.
  final CropController? controller;

  /// The image to be cropped.
  final Image image;

  /// The crop grid color.
  ///
  /// Defaults to 70% white.
  final Color gridColor;

  /// The size of the corner of the crop grid.
  ///
  /// Defaults to 25.
  final double gridCornerSize;

  /// The width of the crop grid thin lines.
  ///
  /// Defaults to 2.
  final double gridThinWidth;

  /// The width of the crop grid thick lines.
  ///
  /// Defaults to 5.
  final double gridThickWidth;

  /// The crop grid scrim (outside area overlay) color.
  ///
  /// Defaults to 54% black.
  final Color scrimColor;

  /// True if third lines of the crop grid are always displayed.
  /// False if third lines are only displayed while the user manipulates the grid.
  ///
  /// Defaults to false.
  final bool alwaysShowThirdLines;

  /// Event called when the user changes the crop rectangle.
  ///
  /// The passed [Rect] is normalized between 0 and 1.
  ///
  /// See also:
  ///
  ///  * [CropController], which can be used to read this and other details of the crop rectangle.
  final ValueChanged<Rect>? onCrop;

  /// The minimum pixel size the crop rectangle can be shrunk to.
  ///
  /// Defaults to 100.
  final double minimumImageSize;

  const CropImage({
    Key? key,
    this.controller,
    required this.image,
    this.gridColor = Colors.white70,
    this.gridCornerSize = 25,
    this.gridThinWidth = 2,
    this.gridThickWidth = 5,
    this.scrimColor = Colors.black54,
    this.alwaysShowThirdLines = false,
    this.onCrop,
    this.minimumImageSize = 100,
  })  : assert(gridCornerSize > 0, 'gridCornerSize cannot be zero'),
        assert(gridThinWidth > 0, 'gridThinWidth cannot be zero'),
        assert(gridThickWidth > 0, 'gridThickWidth cannot be zero'),
        assert(minimumImageSize > 0, 'minimumImageSize cannot be zero'),
        super(key: key);

  @override
  _CropImageState createState() => _CropImageState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties.add(DiagnosticsProperty<CropController>('controller', controller,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Image>('image', image));
    properties.add(DiagnosticsProperty<Color>('gridColor', gridColor));
    properties
        .add(DiagnosticsProperty<double>('gridCornerSize', gridCornerSize));
    properties.add(DiagnosticsProperty<double>('gridThinWidth', gridThinWidth));
    properties
        .add(DiagnosticsProperty<double>('gridThickWidth', gridThickWidth));
    properties.add(DiagnosticsProperty<Color>('scrimColor', scrimColor));
    properties.add(DiagnosticsProperty<bool>(
        'alwaysShowThirdLines', alwaysShowThirdLines));
    properties.add(DiagnosticsProperty<ValueChanged<Rect>>('onCrop', onCrop,
        defaultValue: null));
    properties
        .add(DiagnosticsProperty<double>('minimumImageSize', minimumImageSize));
  }

  static cropImage({required BuildContext context, required Image image}) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CropTheImage(image: image),
        ));
  }
}

enum _CornerTypes { upperLeft, upperRight, lowerRight, lowerLeft, none, move }

class _CropImageState extends State<CropImage> {
  late CropController controller;
  var currentCrop = Rect.zero;
  var size = Size.zero;
  _TouchPoint? panStart;

  Map<_CornerTypes, Offset> get gridCorners => {
        _CornerTypes.upperLeft:
            controller.crop.topLeft.scale(size.width, size.height),
        _CornerTypes.upperRight:
            controller.crop.topRight.scale(size.width, size.height),
        _CornerTypes.lowerRight:
            controller.crop.bottomRight.scale(size.width, size.height),
        _CornerTypes.lowerLeft:
            controller.crop.bottomLeft.scale(size.width, size.height),
      };

  @override
  void initState() {
    super.initState();

    controller = widget.controller ?? CropController();
    controller.addListener(onChange);
    currentCrop = controller.crop;

    widget.image.image //
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener(
            (ImageInfo info, _) => controller.image = info.image));
  }

  @override
  void dispose() {
    controller.removeListener(onChange);
    controller.dispose();

    super.dispose();
  }

  @override
  void didUpdateWidget(CropImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller == null && oldWidget.controller != null) {
      controller = CropController.fromValue(oldWidget.controller!.value);
    } else if (widget.controller != null && oldWidget.controller == null) {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Image(
            image: widget.image.image,
            fit: BoxFit.cover,
          ),
          Positioned.fill(
            child: GestureDetector(
              onPanStart: onPanStart,
              onPanUpdate: onPanUpdate,
              onPanEnd: onPanEnd,
              child: CropGrid(
                crop: currentCrop,
                gridColor: widget.gridColor,
                cornerSize: widget.gridCornerSize,
                thinWidth: widget.gridThinWidth,
                thickWidth: widget.gridThickWidth,
                scrimColor: widget.scrimColor,
                alwaysShowThirdLines: widget.alwaysShowThirdLines,
                isMoving: panStart != null,
                onSize: (size) => this.size = size,
              ),
            ),
          )
        ],
      );

  void onPanStart(DragStartDetails details) {
    if (panStart == null) {
      final type = hitTest(details.localPosition);
      if (type != _CornerTypes.none) {
        var basePoint = gridCorners[
            (type == _CornerTypes.move) ? _CornerTypes.upperLeft : type]!;
        setState(() {
          panStart = _TouchPoint(type, details.localPosition - basePoint);
        });
      }
    }
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (panStart != null) {
      if (panStart!.type == _CornerTypes.move) {
        moveArea(details.localPosition - panStart!.offset);
      } else {
        moveCorner(panStart!.type, details.localPosition - panStart!.offset);
      }
      widget.onCrop?.call(controller.crop);
    }
  }

  void onPanEnd(DragEndDetails details) {
    setState(() {
      panStart = null;
    });
  }

  void onChange() {
    setState(() {
      currentCrop = controller.crop;
    });
  }

  _CornerTypes hitTest(Offset point) {
    for (final gridCorner in gridCorners.entries) {
      final area = Rect.fromCenter(
          center: gridCorner.value,
          width: 2 * widget.gridCornerSize,
          height: 2 * widget.gridCornerSize);
      if (area.contains(point)) return gridCorner.key;
    }

    final area = Rect.fromPoints(gridCorners[_CornerTypes.upperLeft]!,
        gridCorners[_CornerTypes.lowerRight]!);
    return area.contains(point) ? _CornerTypes.move : _CornerTypes.none;
  }

  void moveArea(Offset point) {
    final crop = controller.crop.multiply(size);
    controller.crop = Rect.fromLTWH(
      point.dx.clamp(0, size.width - crop.width),
      point.dy.clamp(0, size.height - crop.height),
      crop.width,
      crop.height,
    ).divide(size);
  }

  void moveCorner(_CornerTypes type, Offset point) {
    final crop = controller.crop.multiply(size);
    var left = crop.left;
    var top = crop.top;
    var right = crop.right;
    var bottom = crop.bottom;

    switch (type) {
      case _CornerTypes.upperLeft:
        left = point.dx.clamp(0, right - widget.minimumImageSize);
        top = point.dy.clamp(0, bottom - widget.minimumImageSize);
        break;
      case _CornerTypes.upperRight:
        right = point.dx.clamp(left + widget.minimumImageSize, size.width);
        top = point.dy.clamp(0, bottom - widget.minimumImageSize);
        break;
      case _CornerTypes.lowerRight:
        right = point.dx.clamp(left + widget.minimumImageSize, size.width);
        bottom = point.dy.clamp(top + widget.minimumImageSize, size.height);
        break;
      case _CornerTypes.lowerLeft:
        left = point.dx.clamp(0, right - widget.minimumImageSize);
        bottom = point.dy.clamp(top + widget.minimumImageSize, size.height);
        break;
      default:
        assert(false);
    }

    if (controller.aspectRatio != null) {
      final width = right - left;
      final height = bottom - top;
      if (width / height > controller.aspectRatio!) {
        switch (type) {
          case _CornerTypes.upperLeft:
          case _CornerTypes.lowerLeft:
            left = right - height * controller.aspectRatio!;
            break;
          case _CornerTypes.upperRight:
          case _CornerTypes.lowerRight:
            right = left + height * controller.aspectRatio!;
            break;
          default:
            assert(false);
        }
      } else {
        switch (type) {
          case _CornerTypes.upperLeft:
          case _CornerTypes.upperRight:
            top = bottom - width / controller.aspectRatio!;
            break;
          case _CornerTypes.lowerRight:
          case _CornerTypes.lowerLeft:
            bottom = top + width / controller.aspectRatio!;
            break;
          default:
            assert(false);
        }
      }
    }

    controller.crop = Rect.fromLTRB(left, top, right, bottom).divide(size);
  }
}

class _TouchPoint {
  final _CornerTypes type;
  final Offset offset;

  _TouchPoint(this.type, this.offset);
}
