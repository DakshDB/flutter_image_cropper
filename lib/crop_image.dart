import 'package:flutter/material.dart';
import 'package:flutter_image_cropper/widgets/custom_button.dart';

import 'controller/crop_controller.dart';
import 'flutter_image_cropper.dart';

class CropTheImage extends StatefulWidget {
  const CropTheImage({Key? key, required this.image}) : super(key: key);

  final Image image;

  @override
  State<CropTheImage> createState() => _CropTheImageState();
}

class _CropTheImageState extends State<CropTheImage> {
  final controller = CropController(
    aspectRatio: 1,
    defaultCrop: const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text("Crop Image"),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: CropImage(
              controller: controller,
              image: widget.image,
            ),
          ),
        ),
        bottomNavigationBar: _buildButtons(),
      );

  Widget _buildButtons() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CustomButton(
              onPressed: () {
                controller.aspectRatio = 1.0;
                controller.crop = const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9);
              },
              buttonText: "Reset"),
          IconButton(
            icon: const Icon(Icons.aspect_ratio),
            onPressed: _aspectRatios,
          ),
          CustomButton(onPressed: _finished, buttonText: "Done"),
        ],
      );

  Future<void> _aspectRatios() async {
    final value = await showDialog<double>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select aspect ratio'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 1.0),
              child: const Text('square'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 2.0),
              child: const Text('2:1'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 4.0 / 3.0),
              child: const Text('4:3'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 16.0 / 9.0),
              child: const Text('16:9'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 9.0 / 16.0),
              child: const Text('9:16'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 0.00),
              child: const Text("Free"),
            ),
          ],
        );
      },
    );
    controller.aspectRatio = value;
    controller.crop = const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9);
  }

  Future<void> _finished() async {
    final image = await controller.croppedBitmap();
    double aspectRatio = image.width / image.height;
    double height, width;
    if (aspectRatio > 1) {
      width = MediaQuery.of(context).size.width / 3;
      height = width / aspectRatio;
    } else {
      height = MediaQuery.of(context).size.height / 2;
      width = height * aspectRatio;
    }

    await showDialog<bool>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          contentPadding: const EdgeInsets.all(6.0),
          titlePadding: const EdgeInsets.all(8.0),
          title: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Preview',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          children: [
            const SizedBox(height: 10),
            SizedBox(
                height: height,
                width: width,
                child: Image(
                  image: UiImageProvider(image),
                  fit: BoxFit.contain,
                )),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomButton(
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      buttonText: "Stay"),
                  CustomButton(
                      onPressed: () {
                        Navigator.pop(context, true);
                        Navigator.pop(context, image);
                      },
                      buttonText: "Done")
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
