import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class OrderInvoiceView extends StatefulWidget {
  const OrderInvoiceView({super.key});

  @override
  State<OrderInvoiceView> createState() => _OrderInvoiceViewState();
}

class _OrderInvoiceViewState extends State<OrderInvoiceView> {
  Uint8List? _imageFile;

  //Create an instance of ScreenshotController
  ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Order Invoice"),
      ),
      body: Column(
        children: [
          Screenshot(
            controller: screenshotController,
            child: Container(
              height: 100,
              color: Colors.blue,
              width: 100,
              child: Center(
                child: Text("Hi"),
              ),
            ),
          ),
          ElevatedButton(
              onPressed: () async {
                await screenshotController
                    .capture(delay: const Duration(milliseconds: 10))
                    .then((Uint8List? image) async {
                      print(image);
                  if (image != null) {
                    final directory = await getApplicationDocumentsDirectory();
                    final imagePath =
                        await File('${directory.path}/image.png').create();
                    await imagePath.writeAsBytes(image);
                    // Convert image to byte data

                    // Save image to gallery
                   try{
                      await ImageGallerySaverPlus.saveImage(image);
                      log("Completed");
                   }catch(e){
                     log(e.toString());
                   }

                    /// Share Plugin
                    await Share.shareXFiles([XFile(imagePath.path)]);
                  }
                });
              },
              child: Text("Share")),
        ],
      ),
    );
  }
}
