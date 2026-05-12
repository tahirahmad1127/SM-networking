import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:sm_networking/infrastructure/model/user.dart';
import 'package:sm_networking/presentation/elements/app_button.dart';
import 'package:sm_networking/presentation/elements/custom_appbar.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../application/user_provider.dart';
import '../../../configurations/frontend_configs.dart';
import '../../../configurations/translation_helper.dart';
import '../../../infrastructure/model/cart.dart';
import '../../../infrastructure/model/order.dart';
import '../../../infrastructure/services/order.dart';
import '../../../infrastructure/services/product.dart';
import '../../elements/custom_text.dart';
import '../../elements/flush_bar.dart';
import '../../elements/processing_widget.dart';
import '../check_out/layout/widgets/items_card.dart';
import '../order/order_placed_view.dart';

class RetailersProfileView extends StatefulWidget {
  final List<CartModel> list;
  final UserModel selectedRetailer;

  const RetailersProfileView(
      {Key? key, required this.list, required this.selectedRetailer})
      : super(key: key);

  @override
  State<RetailersProfileView> createState() => _RetailersProfileViewState();
}

class _RetailersProfileViewState extends State<RetailersProfileView> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    var user = Provider.of<UserProvider>(context);
    return Scaffold(
      appBar: customAppBar(context),
      body: LoadingOverlay(
        isLoading: isLoading,
        progressIndicator: ProcessingWidget(),
        color: Colors.transparent,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        text: TranslationHelper.getTranslatedText(
                            'Order Preview'),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                FrontendConfigs.appDivider,
                ListView.builder(
                    itemCount: widget.list.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, i) {
                      return ItemsCard(
                        model: widget.list[i],
                      );
                    }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 16,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 16,
                          ),
                          Text(
                            TranslationHelper.getTranslatedText(
                                "Selected Retailer"),
                            style: FrontendConfigs.kTitleStyle,
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          // Container(
                          //   height: 120,
                          //   width: MediaQuery.of(context).size.width,
                          //   decoration: BoxDecoration(
                          //     borderRadius: FrontendConfigs.kAppBorder,
                          //     color: FrontendConfigs.kTextFieldColor,
                          //   ),
                          //   child: Row(
                          //     children: [
                          //       SizedBox(
                          //         width: 12,
                          //       ),
                          //       ClipRRect(
                          //         borderRadius: BorderRadius.circular(10),
                          //         child: ExtendedImage.network(
                          //           widget.selectedRetailer.image.toString(),
                          //           height: 100,
                          //           width: 90,
                          //           fit: BoxFit.fill,
                          //           cache: true,
                          //           loadStateChanged:
                          //               (ExtendedImageState state) {
                          //             switch (state.extendedImageLoadState) {
                          //               case LoadState.loading:
                          //                 return Padding(
                          //                   padding: const EdgeInsets.symmetric(
                          //                       vertical: 27.0, horizontal: 10),
                          //                   child: Shimmer.fromColors(
                          //                     baseColor: Colors.grey.shade300,
                          //                     highlightColor:
                          //                         Colors.grey.shade100,
                          //                     child: Image.asset(
                          //                       "assets/images/karyana.png",
                          //                       fit: BoxFit.fill,
                          //                       color: Colors.grey,
                          //                     ),
                          //                   ),
                          //                 );
                          //               case LoadState.failed:
                          //                 return Image.asset(
                          //                   "assets/images/ph.jpg",
                          //                   fit: BoxFit.cover,
                          //                   height: 120,
                          //                   width: 120,
                          //                 );
                          //               default:
                          //                 return state.completedWidget;
                          //             }
                          //           },
                          //           borderRadius: BorderRadius.circular(10),
                          //           //cancelToken: cancellationToken,
                          //         ),
                          //       ),
                          //       SizedBox(
                          //         width: 10,
                          //       ),
                          //       Column(
                          //         crossAxisAlignment: CrossAxisAlignment.start,
                          //         children: [
                          //           SizedBox(
                          //             height: 18,
                          //           ),
                          //           Text(
                          //             widget.selectedRetailer.shopName
                          //                 .toString(),
                          //             style: TextStyle(
                          //                 fontWeight: FontWeight.bold),
                          //           ),
                          //           SizedBox(
                          //             height: 5,
                          //           ),
                          //           Text(
                          //             widget.selectedRetailer.name.toString(),
                          //           ),
                          //           SizedBox(
                          //             height: 5,
                          //           ),
                          //           Text(
                          //             widget.selectedRetailer.phoneNumber
                          //                 .toString(),
                          //           ),
                          //           SizedBox(
                          //             height: 10,
                          //           ),
                          //         ],
                          //       ),
                          //     ],
                          //   ),
                          // ),
                          const SizedBox(
                            height: 10,
                          ),
                          FrontendConfigs.appDivider
                        ],
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 16,
                          ),
                          Text(
                            TranslationHelper.getTranslatedText(
                                "Payment Methods"),
                            style: FrontendConfigs.kTitleStyle,
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/images/cod.png',
                                    height: 50,
                                    width: 50,
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Text(
                                    "Cash on Delivery",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              IconButton(
                                  onPressed: () {},
                                  icon: Icon(
                                    Icons.radio_button_checked,
                                    color: FrontendConfigs.kPrimaryColor,
                                  ))
                            ],
                          ),
                          FrontendConfigs.appDivider
                        ],
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Text(
                        TranslationHelper.getTranslatedText('bill'),
                        style: FrontendConfigs.kTitleStyle,
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText(
                            text: "x ${widget.list.length} Items",
                            fontSize: 12,
                            color: FrontendConfigs.kAuthTextColor,
                          ),
                          CustomText(
                            text: "${1} Rs",
                          )
                        ],
                      ),
                      const SizedBox(
                        height: 11,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText(
                            text: TranslationHelper.getTranslatedText('total'),
                            fontSize: 14,
                            color: FrontendConfigs.kAuthTextColor,
                          ),
                          CustomText(
                            text: "${1} Rs",
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: FrontendConfigs.kPrimaryColor,
                          )
                        ],
                      ),
                      const SizedBox(
                        height: 45,
                      ),
                      AppButton(
                        onPressed: () async {
                          isLoading = true;
                          setState(() {});
                          try {
                            // await OrderServices().createOrder(context,
                            //     model: OrderModel(
                            //         cityID: user
                            //             .getUserDetails()!
                            //             .city!
                            //             .value
                            //             .toString(),
                            //         salesPersonName:
                            //             user.getUserDetails()!.name.toString(),
                            //         salesPersonId:
                            //             user.getUserDetails()!.docId.toString(),
                            //         totalAmount: getCartPrice(widget.list),
                            //         retailerDetails: RetailerDetail(
                            //             deliveryAddress: widget
                            //                 .selectedRetailer.shopAddress1
                            //                 .toString(),
                            //             name: widget.selectedRetailer.name
                            //                 .toString(),
                            //             lat: widget.selectedRetailer.lat!,
                            //             lng: widget.selectedRetailer.lng,
                            //             phoneNumber: widget
                            //                 .selectedRetailer.phoneNumber
                            //                 .toString(),
                            //             retailerId: widget
                            //                 .selectedRetailer.docId
                            //                 .toString()),
                            //         items: widget.list
                            //             .map((e) => Item(
                            //                   amount: e.totalPrice!,
                            //                   image: e.productDetails!.images
                            //                       .toString(),
                            //                   productID: e
                            //                       .productDetails!.productId
                            //                       .toString(),
                            //                   name: e
                            //                       .productDetails!.productName
                            //                       .toString(),
                            //                   quantity: e.quantity,
                            //                   size: e.productDetails!
                            //                       .productDescription
                            //                       .toString(),
                            //                 ))
                            //             .toList()));
                            // widget.list
                            //     .map((e) => ProductServices()
                            //         .reduceProductStock(
                            //             productID: e.productDetails!.productId
                            //                 .toString(),
                            //             quantity: e.quantity!))
                            //     .toList();
                            // widget.list
                            //     .map((e) => CartServices().deleteOneItem(
                            //         docID: e.docID.toString(),
                            //         userID: user
                            //             .getUserDetails()!
                            //             .docId
                            //             .toString()))
                            //     .toList();
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const OrderPlacedView()));
                          } catch (e) {
                            getFlushBar(context, title: e.toString());
                          } finally {
                            isLoading = false;
                            setState(() {});
                          }
                        },
                        btnLabel:
                            TranslationHelper.getTranslatedText('place_order'),
                        btnColor: Colors.black,
                        height: 48,
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  //
  // num getCartPrice(List<CartModel> list) {
  //   num price = 0;
  //   list.map((e) => price += e.totalPrice!).toList();
  //   return price;
  // }
}
