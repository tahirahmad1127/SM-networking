import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:sm_networking/application/discount_helper.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/presentation/elements/custom_text.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../configurations/translation_helper.dart';
import '../../infrastructure/model/product.dart';

class ProductDetailsCard extends StatefulWidget {
  final ProductModel model;

  const ProductDetailsCard({super.key, required this.model});

  @override
  State<ProductDetailsCard> createState() => _ProductDetailsCardState();
}

class _ProductDetailsCardState extends State<ProductDetailsCard> {
  num quantity = 0;
  bool isEnabled = true;

  @override
  Widget build(BuildContext context) {
    var user = Provider.of<UserProvider>(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: FrontendConfigs.kAppBorder,
        color: FrontendConfigs.kTextFieldColor,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: (widget.model.includeBulkOrder == true) ? 10 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.model.includeBulkOrder == true)
              Container(
                height: 20,
                width: 76,
                decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(6),
                        bottomLeft: Radius.circular(6),
                        bottomRight: Radius.circular(6)),
                    color: FrontendConfigs.kPrimaryColor),
                child: Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(6),
                          bottomLeft: Radius.circular(6),
                          bottomRight: Radius.circular(6)),
                    ),
                    child: Center(
                        child: CustomText(
                      text: TranslationHelper.getTranslatedText('bulk_order'),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    )),
                  ),
                ),
              ),
            const SizedBox(
              height: 6,
            ),
            ExtendedImage.network(
              widget.model.image.toString(),
              height: 110,
              width: 167,
              fit: BoxFit.fill,
              cache: true,
              loadStateChanged: (ExtendedImageState state) {
                switch (state.extendedImageLoadState) {
                  case LoadState.loading:
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 27.0, horizontal: 10),
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Image.asset(
                          "assets/images/karyana.png",
                          fit: BoxFit.fill,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  case LoadState.failed:
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 27.0, horizontal: 10),
                      child: Image.asset(
                        "assets/images/karyana.png",
                        fit: BoxFit.fill,
                        color: Colors.grey[350],
                      ),
                    );
                  default:
                    return state.completedWidget;
                }
              },
              borderRadius: const BorderRadius.all(Radius.circular(30.0)),
              //cancelToken: cancellationToken,
            ),
            const SizedBox(
              height: 3,
            ),
            Container(
              height: 90,
              width: 167,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 8,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: CustomText(
                              text: widget.model.englishTitle
                                          .toString()
                                          .length >
                                      15
                                  ? "${widget.model.englishTitle.toString().substring(0, 15)}..."
                                  : widget.model.englishTitle.toString(),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: CustomText(
                              text: widget.model.packings.toString().length > 15
                                  ? "${widget.model.packings.toString().substring(0, 15)}..."
                                  : widget.model.packings.toString(),
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Divider(
                    color: FrontendConfigs.kTextFieldColor,
                    thickness: 1,
                    height: 0,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.model.isDiscounted == true)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CustomText(
                                    text:
                                        "${getDiscountPrice(regularPrice: widget.model.price!, discount: widget.model.discount!)} Rs",
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: FrontendConfigs.kPrimaryColor,
                                  ),
                                  const SizedBox(
                                    width: 4,
                                  ),
                                  Text(
                                    "${widget.model.price.toString()} Rs",
                                    style: TextStyle(
                                        color: FrontendConfigs.kAuthTextColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                        decoration: TextDecoration.lineThrough),
                                  )
                                ],
                              )
                            else
                              CustomText(
                                text: "${widget.model.price.toString()} Rs",
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: FrontendConfigs.kPrimaryColor,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
