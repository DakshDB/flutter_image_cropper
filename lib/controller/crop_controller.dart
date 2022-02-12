import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CropController extends ValueNotifier<_CropControllerValue> {
  double? get aspectRatio => value.aspectRatio;

  set aspectRatio(double? newAspectRatio) {
    if (newAspectRatio != null) {
      value = value.copyWith(
          aspectRatio: newAspectRatio,
          crop: _adjustRatio(value.crop, newAspectRatio));
    } else {
      value = value.copyWith(aspectRatio: newAspectRatio);
    }
    notifyListeners();
  }

  Rect get crop => value.crop;

  set crop(Rect newCrop) {
    if (value.aspectRatio != null) {
      value = value.copyWith(crop: _adjustRatio(newCrop, value.aspectRatio!));
    } else {
      value = value.copyWith(crop: newCrop);
    }
    notifyListeners();
  }

  Rect get cropSize => value.crop.multiply(_bitmapSize);

  set cropSize(Rect newCropSize) {
    if (value.aspectRatio != null) {
      value = value.copyWith(
          crop: _adjustRatio(
              newCropSize.divide(_bitmapSize), value.aspectRatio!));
    } else {
      value = value.copyWith(crop: newCropSize.divide(_bitmapSize));
    }
    notifyListeners();
  }

  late ui.Image _bitmap;
  late Size _bitmapSize;

  set image(ui.Image newImage) {
    _bitmap = newImage;
    _bitmapSize = Size(newImage.width.toDouble(), newImage.height.toDouble());
    aspectRatio = aspectRatio; // force adjustment
    notifyListeners();
  }

  CropController({
    double? aspectRatio,
    Rect defaultCrop = const Rect.fromLTWH(0, 0, 1, 1),
  })  : assert(defaultCrop.left >= 0 && defaultCrop.left <= 1,
            'left should be 0..1'),
        assert(defaultCrop.right >= 0 && defaultCrop.right <= 1,
            'right should be 0..1'),
        assert(
            defaultCrop.top >= 0 && defaultCrop.top <= 1, 'top should be 0..1'),
        assert(defaultCrop.bottom >= 0 && defaultCrop.bottom <= 1,
            'bottom should be 0..1'),
        assert(defaultCrop.left < defaultCrop.right,
            'left must be less than right'),
        assert(defaultCrop.top < defaultCrop.bottom,
            'top must be less than bottom'),
        super(_CropControllerValue(aspectRatio, defaultCrop));

  CropController.fromValue(_CropControllerValue value) : super(value);

  Rect _adjustRatio(Rect rect, double aspectRatio) {
    if (aspectRatio != 0) {
      final width = rect.width * _bitmapSize.width;
      final height = rect.height * _bitmapSize.height;
      if (width / height > aspectRatio) {
        final w = height * aspectRatio / _bitmapSize.width;
        return Rect.fromLTWH(rect.center.dx - w / 2, rect.top, w, rect.height);
      } else {
        final h = width / aspectRatio / _bitmapSize.height;
        return Rect.fromLTWH(rect.left, rect.center.dy - h / 2, rect.width, h);
      }
    }
    return rect;
  }

  Future<ui.Image> croppedBitmap(
      {ui.FilterQuality quality = FilterQuality.high}) async {
    final pictureRecorder = ui.PictureRecorder();
    Canvas(pictureRecorder).drawImageRect(
      _bitmap,
      cropSize,
      Offset.zero & cropSize.size,
      Paint()..filterQuality = quality,
    );
    return await pictureRecorder
        .endRecording()
        .toImage(cropSize.width.round(), cropSize.height.round());
  }

  Future<Image> croppedImage(
      {ui.FilterQuality quality = FilterQuality.high}) async {
    return Image(
      image: UiImageProvider(await croppedBitmap(quality: quality)),
      fit: BoxFit.contain,
    );
  }
}

@immutable
class _CropControllerValue {
  final double? aspectRatio;
  final Rect crop;

  const _CropControllerValue(this.aspectRatio, this.crop);

  _CropControllerValue copyWith({double? aspectRatio, Rect? crop}) =>
      _CropControllerValue(
        aspectRatio ?? this.aspectRatio,
        crop ?? this.crop,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    } else {
      return (other is _CropControllerValue &&
          other.aspectRatio == aspectRatio &&
          other.crop == crop);
    }
  }

  @override
  int get hashCode => hashValues(aspectRatio.hashCode, crop.hashCode);
}

class UiImageProvider extends ImageProvider<UiImageProvider> {
  final ui.Image image;

  const UiImageProvider(this.image);

  @override
  Future<UiImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<UiImageProvider>(this);

  @override
  ImageStreamCompleter load(UiImageProvider key, DecoderCallback decode) =>
      OneFrameImageStreamCompleter(_loadAsync(key));

  Future<ImageInfo> _loadAsync(UiImageProvider key) async {
    assert(key == this);
    return ImageInfo(image: image);
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final UiImageProvider typedOther = other;
    return image == typedOther.image;
  }

  @override
  int get hashCode => image.hashCode;
}

extension RectExtensions on Rect {
  Rect multiply(Size size) => Rect.fromLTRB(
        left * size.width,
        top * size.height,
        right * size.width,
        bottom * size.height,
      );

  Rect divide(Size size) => Rect.fromLTRB(
        left / size.width,
        top / size.height,
        right / size.width,
        bottom / size.height,
      );
}
