import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:intl/intl.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/presentation/elements/custom_text.dart';
import 'package:sm_networking/presentation/elements/flush_bar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../infrastructure/model/order.dart';
import '../../../elements/app_button.dart';

class ReceiptBody extends StatelessWidget {
  final OrderModel model;

  ReceiptBody({super.key, required this.model});

  Uint8List? _imageFile;

  //Create an instance of ScreenshotController
  ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FrontendConfigs.kPrimaryColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppButton(
                    onPressed: () async {
                      await screenshotController.capture(delay: const Duration(milliseconds: 10))
                          .then((Uint8List? image) async {
                        print(image);
                        if (image != null) {
                          final directory = await getApplicationDocumentsDirectory();
                          final imagePath = await File('${directory.path}/image.png').create();
                          await imagePath.writeAsBytes(image);
                          // Convert image to byte data

                          /// Share Plugin
                          await Share.shareXFiles([XFile(imagePath.path)]);
                        }
                      });

                    },
                    btnLabel: "Share",
                    btnColor: Colors.black,
                    width: MediaQuery.of(context).size.width / 2.2,
                  ),
                  AppButton(
                    onPressed: () async {
                      await screenshotController.capture(delay: const Duration(milliseconds: 10))
                          .then((Uint8List? image) async {
                        print(image);
                        if (image != null) {
                          final directory = await getApplicationDocumentsDirectory();
                          final imagePath = await File('${directory.path}/image.png').create();
                          await imagePath.writeAsBytes(image);
                          // Convert image to byte data

                          // Save image to gallery
                          try {
                            await ImageGallerySaverPlus.saveImage(image);
                            log("Completed");
                            getFlushBar(context, title: "Image has been saved to gallery.");
                          } catch (e) {
                            log(e.toString());
                          }
                        }
                      });
                    },
                    btnLabel: "Download",
                    btnColor: FrontendConfigs.kPrimaryColor,
                    width: MediaQuery.of(context).size.width / 2.2,
                  )
                ],
              ),
            )
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 12,
              ),
              Screenshot(
                controller: screenshotController,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(10),
                            topLeft: Radius.circular(10),
                          ),
                          color: Colors.white),
                      width: MediaQuery.of(context).size.width,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 18,
                          ),
                          Text(
                            "Prime Link",
                            style: TextStyle(
                                fontFamily: "KronaOne",
                                fontWeight: FontWeight.w400,
                                fontSize: 24.5,
                                color: FrontendConfigs.kPrimaryColor),
                          ),
                          SizedBox(
                            height: 24,
                          ),
                          Text(
                            "Sale Invoice",
                            style: FrontendConfigs.kSubHeadingStyle,
                          ),
                          SizedBox(
                            height: 18,
                          ),
                          CustomText(
                            text: DateFormat("EEE, dd MMM yyyy 'at' hh:mm a").format(model.createdAt!),
                            color: FrontendConfigs.kAuthTextColor,
                          ),

                          SizedBox(
                            height: 18,
                          ),

                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomText(
                                text: "Reference:",
                                fontWeight: FontWeight.w600,
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              CustomText(
                                text:
                                "#${model.id.toString().substring(0, 6).toUpperCase()}",
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: FrontendConfigs.kAuthTextColor,
                              ),
                            ],
                          ),

                          SizedBox(
                            height: 18,
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width + 2,
                            child: Image.asset(
                              "assets/images/receipt_divider.png",
                              fit: BoxFit.fitWidth,
                            ),
                          ),
                          SizedBox(
                            height: 18,
                          ),
                          Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18.0),
                                child: Column(
                                  children: [
                                    _rowWidget(
                                        title: 'Order by:',
                                        details: model.retailerUser!.name
                                            .toString()),
                                    SizedBox(
                                      height: 18,
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CustomText(text: "Items:"),
                                        Flexible( // <-- Ensures right side adapts without overflowing
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              ...model.items!.map((e) {
                                                return Padding(
                                                  padding: const EdgeInsets.only(bottom: 3.0),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded( // <-- Safely expand within available space
                                                        child: CustomText(
                                                          text: e.productId!.englishTitle.toString(),
                                                          fontWeight: FontWeight.w600,
                                                          textAlign: TextAlign.end,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      CustomText(
                                                        text: "x ${e.quantity} ${_formatUnit(e.type)}",
                                                        fontWeight: FontWeight.w600,
                                                        color: FrontendConfigs.kPrimaryColor,
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 18,
                                    ),
                                    // _rowWidget(
                                    //     title: 'Items Price:',
                                    //     details:
                                    //         '${model.total!.toStringAsFixed(0)} Rs'),
                                    // SizedBox(
                                    //   height: 6,
                                    // ),
                                    _rowWidget(
                                        title: 'Total Bill:',
                                        details:
                                            '${model.total!.toStringAsFixed(0)} Rs'),
                                    SizedBox(
                                      height: 18,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width + 2,
                                child: Image.asset(
                                  "assets/images/receipt_divider.png",
                                  fit: BoxFit.fitWidth,
                                ),
                              ),
                              SizedBox(
                                height: 18,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: FrontendConfigs.kAppBorder,
                                  color: Color(0xffEEF4EB),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: CustomText(
                                    text:
                                    '${model.total!.toStringAsFixed(0)} Rs',
                                    fontWeight: FontWeight.w700,
                                    color: FrontendConfigs.kPrimaryColor,
                                    fontSize: 32,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 35,
                          )
                        ],
                      ),
                    ),
                    Image.asset(
                      "assets/images/receipt_bottom.png",
                    ),
                    SizedBox(
                      height: 30,
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatUnit(String? type) {
    switch (type?.toLowerCase()) {
      case 'piece':
      case 'pcs':
        return 'PCS';
      case 'ctn':
        return 'CTN';
      default:
        return type ?? '';
    }
  }


  Widget _rowWidget({required String title, required String details}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(text: title),
        CustomText(
          text: details,
          fontWeight: FontWeight.w600,
        ),
      ],
    );
  }
}
