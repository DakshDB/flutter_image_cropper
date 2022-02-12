import 'package:flutter/material.dart';
import 'package:flutter_image_cropper/controller/crop_controller.dart';
import 'package:flutter_image_cropper/flutter_image_cropper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Image _image = Image.asset('images/test_image.jpg');
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Column(
          children: [
            SizedBox(
                height: MediaQuery.of(context).size.height / 2,
                width: MediaQuery.of(context).size.width / 2,
                child: _image),
            Center(
              child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      var image = await CropImage.cropImage(
                          context: context,
                          image: Image.asset('images/test_image.jpg'));
                      setState(() {
                        _image = Image(
                          image: UiImageProvider(image),
                          fit: BoxFit.contain,
                        );
                      });
                    },
                    child: const Text("Open Cropper"),
                  )),
            ),
          ],
        ),
      );
}
