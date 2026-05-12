import 'dart:developer';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sm_networking/application/cart_provider.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/infrastructure/model/bulk.dart';
import 'package:sm_networking/infrastructure/model/product.dart';
import 'package:sm_networking/infrastructure/services/product.dart';
import 'package:sm_networking/presentation/elements/custom_text.dart';
import 'package:sm_networking/presentation/elements/processing_widget.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../application/discount_helper.dart';
import '../../../../infrastructure/model/ordered_prduct_model.dart';
import '../../../../utils/utils.dart';
import '../../../elements/app_button.dart';
import '../../../elements/flush_bar.dart';

class ProductDetailsBody extends StatefulWidget {
  final ProductModel model;

  const ProductDetailsBody({Key? key, required this.model}) : super(key: key);

  @override
  State<ProductDetailsBody> createState() => _ProductDetailsBodyState();
}

class _ProductDetailsBodyState extends State<ProductDetailsBody> {
  num quantity = 0;
  num selectedBulkDiscount = -1;
  num selectedBulkIndex = -1;
  bool isEnabled = true;

  @override
  Widget build(BuildContext context) {
    var user = Provider.of<UserProvider>(context);
    var cart = Provider.of<CartProvider>(context);
    return Container(
      decoration: BoxDecoration(
        // <--- add this
        borderRadius: BorderRadius.circular(25),
      ),
      height: 670,
      clipBehavior: Clip.antiAlias, // <--- add this
      child: Scaffold(
        bottomNavigationBar: cart.cartItems.isEmpty
            ? null
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 70,
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                      top: BorderSide(
                          color: FrontendConfigs.kAuthTextColor,
                          width: 0.3))),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18.0, vertical: 10),
                child: AppButton(
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                  btnLabel: "Confirm",
                  width: double.infinity,
                  btnColor: Colors.black,
                  height: 48,
                ),
              ),
            ),
          ],
        ),
        // body: StreamProvider.value(
        //     value: ProductServices()
        //         .streamProductByID(widget.model.docID.toString()),
        //     initialData: ProductModel(),
        //     builder: (context, child) {
        //       ProductModel model = context.watch<ProductModel>();
        //       return model.docID == null
        //           ? Center(
        //         child: ProcessingWidget(),
        //       )
        //           : StreamProvider.value(
        //           value: ProductServices().streamProductBulkDetails(
        //               widget.model.docID.toString()),
        //           initialData: [BulkModel()],
        //           builder: (context, child) {
        //             List<BulkModel> bulkModel =
        //             context.watch<List<BulkModel>>();
        //
        //             if (bulkModel.isNotEmpty) {
        //               if (bulkModel[0].quantity != null) {
        //                 log("Bulk Stream Called");
        //                 getSelectedBulkIndex(bulkModel, false);
        //               }
        //             }
        //             return Container(
        //               decoration: BoxDecoration(
        //                 borderRadius: new BorderRadius.only(
        //                     topLeft: const Radius.circular(25.0),
        //                     topRight: const Radius.circular(25.0)),
        //               ),
        //               child: Column(
        //                 mainAxisSize: MainAxisSize.min,
        //                 children: [
        //                   SizedBox(
        //                     height: 10,
        //                   ),
        //                   Center(
        //                     child: Container(
        //                       height: 5,
        //                       width: 90,
        //                       decoration: BoxDecoration(
        //                           color: FrontendConfigs
        //                               .kAuthTextColor
        //                               .withOpacity(0.5),
        //                           borderRadius:
        //                           BorderRadius.circular(10)),
        //                     ),
        //                   ),
        //                   SizedBox(
        //                     height: 10,
        //                   ),
        //                   Container(
        //                     height: 270,
        //                     width: MediaQuery.of(context).size.width,
        //                     color: FrontendConfigs.kTextFieldColor,
        //                     child: ExtendedImage.network(
        //                       widget.model.image.toString(),
        //                       height: 129,
        //                       width: 167,
        //                       fit: BoxFit.fill,
        //                       cache: true,
        //                       loadStateChanged:
        //                           (ExtendedImageState state) {
        //                         switch (
        //                         state.extendedImageLoadState) {
        //                           case LoadState.loading:
        //                             return Padding(
        //                               padding:
        //                               const EdgeInsets.symmetric(
        //                                   vertical: 27.0,
        //                                   horizontal: 10),
        //                               child: Shimmer.fromColors(
        //                                 baseColor:
        //                                 Colors.grey.shade300,
        //                                 highlightColor:
        //                                 Colors.grey.shade100,
        //                                 child: Image.asset(
        //                                   "assets/images/karyana.png",
        //                                   fit: BoxFit.fill,
        //                                   color: Colors.grey,
        //                                 ),
        //                               ),
        //                             );
        //                           case LoadState.failed:
        //                             return Padding(
        //                               padding:
        //                               const EdgeInsets.symmetric(
        //                                   vertical: 27.0,
        //                                   horizontal: 10),
        //                               child: Shimmer.fromColors(
        //                                 baseColor:
        //                                 Colors.grey.shade300,
        //                                 highlightColor:
        //                                 Colors.grey.shade100,
        //                                 child: Image.asset(
        //                                   "assets/images/karyana.png",
        //                                   fit: BoxFit.fill,
        //                                   color: Colors.grey,
        //                                 ),
        //                               ),
        //                             );
        //                           default:
        //                             return state.completedWidget;
        //                         }
        //                       },
        //                       borderRadius: BorderRadius.all(
        //                           Radius.circular(30.0)),
        //                       //cancelToken: cancellationToken,
        //                     ),
        //                   ),
        //                   const SizedBox(
        //                     height: 24,
        //                   ),
        //                   Padding(
        //                     padding: const EdgeInsets.symmetric(
        //                         horizontal: 18.0),
        //                     child: Column(
        //                       mainAxisSize: MainAxisSize.min,
        //                       crossAxisAlignment:
        //                       CrossAxisAlignment.start,
        //                       children: [
        //                         Row(
        //                           mainAxisAlignment:
        //                           MainAxisAlignment.spaceBetween,
        //                           children: [
        //                             Column(
        //                               crossAxisAlignment:
        //                               CrossAxisAlignment.start,
        //                               children: [
        //                                 CustomText(
        //                                   text: widget
        //                                       .model.englishName
        //                                       .toString(),
        //                                   fontSize: 20,
        //                                   fontWeight: FontWeight.w700,
        //                                 ),
        //                                 SizedBox(
        //                                   height: 5,
        //                                 ),
        //                                 CustomText(
        //                                   text: widget
        //                                       .model.packagingDetails
        //                                       .toString(),
        //                                   fontSize: 13,
        //                                   fontWeight: FontWeight.w700,
        //                                   color: FrontendConfigs
        //                                       .kAuthTextColor,
        //                                 ),
        //                                 SizedBox(
        //                                   height: 10,
        //                                 ),
        //                                 CustomText(
        //                                   text: widget
        //                                       .model.categoryName
        //                                       .toString(),
        //                                   color: FrontendConfigs
        //                                       .kAuthTextColor,
        //                                   fontSize: 15,
        //                                 ),
        //                                 SizedBox(
        //                                   height: 10,
        //                                 ),
        //                                 if (widget
        //                                     .model.isOnDiscount!)
        //                                   Row(
        //                                     children: [
        //                                       CustomText(
        //                                         text:
        //                                         "${getDiscountPrice(regularPrice: widget.model.price!, discount: widget.model.discountPrice!)} Rs",
        //                                         fontSize: 16,
        //                                         fontWeight:
        //                                         FontWeight.w600,
        //                                         color: FrontendConfigs
        //                                             .kPrimaryColor,
        //                                       ),
        //                                       SizedBox(
        //                                         width: 10,
        //                                       ),
        //                                       Text(
        //                                         "${widget.model.price.toString()} Rs",
        //                                         style: TextStyle(
        //                                             fontWeight:
        //                                             FontWeight
        //                                                 .w500,
        //                                             fontSize: 12,
        //                                             decoration:
        //                                             TextDecoration
        //                                                 .lineThrough),
        //                                       ),
        //                                     ],
        //                                   )
        //                                 else
        //                                   Row(
        //                                     children: [
        //                                       CustomText(
        //                                         text:
        //                                         "${widget.model.price.toString()} Rs",
        //                                         fontSize: 16,
        //                                         fontWeight:
        //                                         FontWeight.w600,
        //                                         color: FrontendConfigs
        //                                             .kPrimaryColor,
        //                                       ),
        //                                     ],
        //                                   )
        //                               ],
        //                             ),
        //                             InkWell(
        //                               splashColor: Colors.transparent,
        //                               highlightColor:
        //                               Colors.transparent,
        //                               onTap: () {
        //                                 if (model.favoriteUser!
        //                                     .contains(user
        //                                     .getUserDetails()!
        //                                     .docId
        //                                     .toString())) {
        //                                   ProductServices()
        //                                       .removeProductFromFavorite(
        //                                       userID: user
        //                                           .getUserDetails()!
        //                                           .docId
        //                                           .toString(),
        //                                       productID: model
        //                                           .docID
        //                                           .toString());
        //                                 } else {
        //                                   ProductServices()
        //                                       .addProductToFavorite(
        //                                       userID: user
        //                                           .getUserDetails()!
        //                                           .docId
        //                                           .toString(),
        //                                       productID: model
        //                                           .docID
        //                                           .toString());
        //                                 }
        //                               },
        //                               child: Container(
        //                                 height: 38,
        //                                 width: 38,
        //                                 decoration: BoxDecoration(
        //                                     borderRadius:
        //                                     BorderRadius.circular(
        //                                         10),
        //                                     border: Border.all(
        //                                       color: FrontendConfigs
        //                                           .kAuthTextColor
        //                                           .withOpacity(0.5),
        //                                     )),
        //                                 child: Padding(
        //                                   padding:
        //                                   const EdgeInsets.all(
        //                                       6.0),
        //                                   child: !model.favoriteUser!
        //                                       .contains(user
        //                                       .getUserDetails()!
        //                                       .docId
        //                                       .toString())
        //                                       ? Icon(
        //                                     CupertinoIcons
        //                                         .heart,
        //                                     color: FrontendConfigs
        //                                         .kAuthTextColor,
        //                                   )
        //                                       : Icon(
        //                                     CupertinoIcons
        //                                         .heart_fill,
        //                                     color: FrontendConfigs
        //                                         .kPrimaryColor,
        //                                   ),
        //                                 ),
        //                               ),
        //                             )
        //                           ],
        //                         ),
        //                         if (bulkModel.isNotEmpty)
        //                           if (bulkModel[0].discount != null)
        //                             const SizedBox(
        //                               height: 5,
        //                             ),
        //                         if (bulkModel.isNotEmpty)
        //                           if (bulkModel[0].discount != null)
        //                             Divider(),
        //                         if (bulkModel.isNotEmpty)
        //                           if (bulkModel[0].discount != null)
        //                             const SizedBox(
        //                               height: 5,
        //                             ),
        //                         if (bulkModel.isNotEmpty)
        //                           if (bulkModel[0].discount != null)
        //                             Column(
        //                               crossAxisAlignment:
        //                               CrossAxisAlignment.start,
        //                               children: [
        //                                 Text(
        //                                   "Bulk Discount",
        //                                   style: FrontendConfigs
        //                                       .kTitleStyle,
        //                                 ),
        //                                 const SizedBox(
        //                                   height: 14,
        //                                 ),
        //                                 SizedBox(
        //                                   height: 50,
        //                                   child: ListView.builder(
        //                                       itemCount:
        //                                       bulkModel.length,
        //                                       shrinkWrap: true,
        //                                       scrollDirection:
        //                                       Axis.horizontal,
        //                                       physics:
        //                                       const BouncingScrollPhysics(),
        //                                       itemBuilder:
        //                                           (context, i) {
        //                                         return Padding(
        //                                           padding:
        //                                           const EdgeInsets
        //                                               .only(
        //                                               right: 5.0),
        //                                           child: Container(
        //                                             height: 50,
        //                                             decoration: BoxDecoration(
        //                                                 borderRadius:
        //                                                 FrontendConfigs
        //                                                     .kAppBorder,
        //                                                 color: selectedBulkIndex ==
        //                                                     i
        //                                                     ? FrontendConfigs
        //                                                     .kPrimaryColor
        //                                                     .withOpacity(
        //                                                     0.4)
        //                                                     : FrontendConfigs
        //                                                     .kTextFieldColor),
        //                                             child: Padding(
        //                                               padding: const EdgeInsets
        //                                                   .symmetric(
        //                                                   horizontal:
        //                                                   8.0),
        //                                               child: Row(
        //                                                 mainAxisAlignment:
        //                                                 MainAxisAlignment
        //                                                     .center,
        //                                                 children: [
        //                                                   Column(
        //                                                     mainAxisAlignment:
        //                                                     MainAxisAlignment
        //                                                         .center,
        //                                                     crossAxisAlignment:
        //                                                     CrossAxisAlignment
        //                                                         .start,
        //                                                     children: [
        //                                                       CustomText(
        //                                                         text: bulkModel[i].quantity.toString() +
        //                                                             "+ Items",
        //                                                         fontSize:
        //                                                         12,
        //                                                         fontWeight:
        //                                                         FontWeight.w500,
        //                                                         color:
        //                                                         FrontendConfigs.kAuthTextColor,
        //                                                       ),
        //                                                       CustomText(
        //                                                         text: (getDiscountPrice(regularPrice: widget.model.isOnDiscount! ? getDiscountPrice(regularPrice: widget.model.price!, discount: widget.model.discountPrice!) : widget.model.price!, discount: bulkModel[i].discount!) * bulkModel[i].quantity!).toStringAsFixed(0) +
        //                                                             " Rs",
        //                                                         fontSize:
        //                                                         14,
        //                                                         fontWeight:
        //                                                         FontWeight.w500,
        //                                                         color:
        //                                                         Colors.black,
        //                                                       )
        //                                                     ],
        //                                                   ),
        //                                                 ],
        //                                               ),
        //                                             ),
        //                                           ),
        //                                         );
        //                                       }),
        //                                 )
        //                               ],
        //                             )
        //                       ],
        //                     ),
        //                   ),
        //                   const SizedBox(
        //                     height: 18,
        //                   ),
        //                   Padding(
        //                     padding: const EdgeInsets.symmetric(
        //                         horizontal: 18.0),
        //                     child: Row(
        //                       mainAxisAlignment:
        //                       MainAxisAlignment.spaceBetween,
        //                       children: [
        //                         Text(
        //                           "Select Quantity",
        //                           style: FrontendConfigs.kTitleStyle,
        //                         ),
        //                         SizedBox(
        //                           width: 147,
        //                           child: Row(
        //                             mainAxisAlignment:
        //                             _cartList.isEmpty
        //                                 ? MainAxisAlignment.end
        //                                 : MainAxisAlignment
        //                                 .spaceBetween,
        //                             children: [
        //                               if (_cartList.isNotEmpty)
        //                                 InkWell(
        //                                   borderRadius:
        //                                   FrontendConfigs
        //                                       .kAppBorder,
        //                                   onTap: () async {
        //                                     if (!isEnabled) {
        //                                       return;
        //                                     }
        //                                     isEnabled = false;
        //
        //                                     setState(() {});
        //
        //                                     if (quantity <= 1) {
        //                                       await CartServices()
        //                                           .deleteOneItem(
        //                                           docID: _cartList[
        //                                           0]
        //                                               .docID
        //                                               .toString(),
        //                                           userID: user
        //                                               .getUserDetails()!
        //                                               .docId
        //                                               .toString());
        //                                       isEnabled = true;
        //                                       setState(() {});
        //                                     } else {
        //                                       await CartServices()
        //                                           .decrementProductQuantity(
        //                                           context,
        //                                           productID:
        //                                           _cartList[0]
        //                                               .docID
        //                                               .toString(),
        //                                           updatedPrice:
        //                                           widget.model
        //                                               .price!,
        //                                           uid: user
        //                                               .getUserDetails()!
        //                                               .docId
        //                                               .toString());
        //                                       isEnabled = true;
        //                                       setState(() {});
        //                                       quantity--;
        //                                       setState(() {});
        //                                       getSelectedBulkIndex(
        //                                           bulkModel);
        //                                     }
        //                                   },
        //                                   child: Container(
        //                                     height: 35,
        //                                     width: 35,
        //                                     decoration: BoxDecoration(
        //                                         borderRadius:
        //                                         FrontendConfigs
        //                                             .kAppBorder,
        //                                         color: quantity == 1
        //                                             ? FrontendConfigs
        //                                             .kTextFieldColor
        //                                             : Colors.grey),
        //                                     child: Icon(
        //                                         quantity <= 1
        //                                             ? Icons.delete
        //                                             : Icons.remove,
        //                                         color: quantity <= 1
        //                                             ? Colors.red
        //                                             : Colors.white),
        //                                   ),
        //                                 ),
        //                               if (_cartList.isNotEmpty)
        //                                 CustomText(
        //                                   text: quantity.toString(),
        //                                   fontSize: 16,
        //                                 ),
        //                               InkWell(
        //                                 borderRadius: FrontendConfigs
        //                                     .kAppBorder,
        //                                 onTap: () async {
        //                                   if (!isEnabled) {
        //                                     return;
        //                                   }
        //
        //                                   if (_cartList.isEmpty) {
        //                                     await getSelectedBulkIndex(
        //                                         bulkModel);
        //                                     isEnabled = false;
        //                                     quantity++;
        //                                     setState(() {});
        //                                     await CartServices().addToCart(
        //                                         context,
        //                                         model: CartModel(
        //                                             quantity: 1,
        //                                             totalPrice: widget
        //                                                 .model
        //                                                 .isOnDiscount!
        //                                                 ? getDiscountPrice(
        //                                                 regularPrice: widget
        //                                                     .model
        //                                                     .price!,
        //                                                 discount: widget
        //                                                     .model
        //                                                     .discountPrice!)
        //                                                 .toInt()
        //                                                 : widget
        //                                                 .model.price!
        //                                                 .toInt(),
        //                                             uid: user
        //                                                 .getUserDetails()!
        //                                                 .docId
        //                                                 .toString(),
        //                                             productDetails:
        //                                             OrderedProductModel(
        //                                               productId: widget
        //                                                   .model.docID
        //                                                   .toString(),
        //                                               catId: widget
        //                                                   .model
        //                                                   .categoryId
        //                                                   .toString(),
        //                                               images: widget
        //                                                   .model
        //                                                   .image,
        //                                               price: widget
        //                                                   .model
        //                                                   .isOnDiscount!
        //                                                   ? selectedBulkDiscount !=
        //                                                   -1
        //                                                   ? getDiscountPrice(regularPrice: getDiscountPrice(regularPrice: widget.model.price!, discount: widget.model.discountPrice!), discount: selectedBulkDiscount)
        //                                                   .toString()
        //                                                   : getDiscountPrice(regularPrice: widget.model.price!, discount: widget.model.discountPrice!)
        //                                                   .toString()
        //                                                   : getDiscountPrice(
        //                                                   regularPrice:
        //                                                   widget.model.price!,
        //                                                   discount: selectedBulkDiscount)
        //                                                   .toString(),
        //                                               productName: widget
        //                                                   .model
        //                                                   .englishName
        //                                                   .toString(),
        //                                               productDescription: widget
        //                                                   .model
        //                                                   .packagingDetails
        //                                                   .toString(),
        //                                               address: "",
        //                                             )),
        //                                         uid: user
        //                                             .getUserDetails()!
        //                                             .docId
        //                                             .toString());
        //                                     isEnabled = true;
        //                                     setState(() {});
        //                                   } else {
        //                                     if (quantity >=
        //                                         widget.model.stock!) {
        //                                       getFlushBar(context,
        //                                           title:
        //                                           "Sorry! You cannot order more than ${widget.model.stock.toString()} items.");
        //                                     } else {
        //                                       isEnabled = false;
        //                                       quantity++;
        //
        //                                       setState(() {});
        //                                       getSelectedBulkIndex(
        //                                           bulkModel);
        //                                       await CartServices()
        //                                           .incrementProductQuantity(
        //                                           context,
        //                                           productID:
        //                                           _cartList[0]
        //                                               .docID
        //                                               .toString(),
        //                                           updatedPrice:
        //                                           widget.model
        //                                               .price!,
        //                                           uid: user
        //                                               .getUserDetails()!
        //                                               .docId
        //                                               .toString());
        //                                       isEnabled = true;
        //                                       setState(() {});
        //                                     }
        //                                   }
        //                                 },
        //                                 child: Container(
        //                                   height: 35,
        //                                   width: 35,
        //                                   decoration: BoxDecoration(
        //                                       borderRadius:
        //                                       FrontendConfigs
        //                                           .kAppBorder,
        //                                       color: _cartList
        //                                           .isNotEmpty
        //                                           ? quantity >=
        //                                           widget.model
        //                                               .stock!
        //                                           ? Colors.grey
        //                                           : Colors.black
        //                                           : Colors.black),
        //                                   child: Icon(Icons.add,
        //                                       color: Colors.white),
        //                                 ),
        //                               )
        //                             ],
        //                           ),
        //                         ),
        //                       ],
        //                     ),
        //                   ),
        //                 ],
        //               ),
        //             );
        //           });
        //     }),
      ),
    );
  }

  Future getSelectedBulkIndex(List<BulkModel> list,
      [bool callSetState = true]) async {
    log("Bulk Index Called");

    list.map((e) {
      int i = list.indexOf(e);
      log((quantity).toString() + " Qauntity");
      log(e.quantity.toString() + " E.Q");
      if (quantity >= e.quantity!) {
        selectedBulkIndex = list.indexOf(e);
        selectedBulkDiscount = list.indexOf(e);
        if (callSetState) {
          setState(() {});
        }
        log(selectedBulkIndex.toString() + " Selected Bulk Index");
      }
    }).toList();
    return Future.value(true);
  }
}
