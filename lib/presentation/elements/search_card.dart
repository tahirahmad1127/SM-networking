import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sm_networking/application/discount_helper.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/configurations/translation_helper.dart';
import 'package:sm_networking/infrastructure/services/product.dart';
import 'package:sm_networking/presentation/elements/app_button.dart';
import 'package:sm_networking/presentation/elements/custom_text.dart';
import 'package:sm_networking/presentation/view/cart/cart_view.dart';
import 'package:sm_networking/presentation/view/product_details/product_details_view.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../infrastructure/model/bulk.dart';
import '../../infrastructure/model/ordered_prduct_model.dart';
import '../../infrastructure/model/product.dart';
import 'flush_bar.dart';

class SearchCard extends StatelessWidget {
  final ProductModel model;

  SearchCard({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var user = Provider.of<UserProvider>(context);
    return SizedBox();
    // return StreamProvider.value(
    //     value: CartServices().streamSpecificProduct(
    //         model.docID.toString(), user.getUserDetails()!.docId.toString()),
    //     initialData: [CartModel()],
    //     builder: (context, child) {
    //       List<CartModel> _cartList = context.watch<List<CartModel>>();
    //       return StreamProvider.value(
    //           value: ProductServices()
    //               .streamProductBulkDetails(model.docID.toString()),
    //           initialData: [BulkModel()],
    //           builder: (context, child) {
    //             List<BulkModel> _list = context.watch<List<BulkModel>>();
    //             return InkWell(
    //               onTap: () {
    //                 Navigator.push(
    //                     context,
    //                     MaterialPageRoute(
    //                         builder: (context) => ProductDetailsView(
    //                               model: model,
    //                             )));
    //               },
    //               child: Container(
    //                 decoration: BoxDecoration(
    //                   borderRadius: FrontendConfigs.kAppBorder,
    //                   color: FrontendConfigs.kTextFieldColor,
    //                 ),
    //                 child: Padding(
    //                   padding: const EdgeInsets.symmetric(
    //                       horizontal: 8.0, vertical: 12),
    //                   child: Column(
    //                     crossAxisAlignment: CrossAxisAlignment.start,
    //                     children: [
    //                       if (_list.isNotEmpty)
    //                         Container(
    //                           height: 26,
    //                           width: 76,
    //                           decoration: BoxDecoration(
    //                               borderRadius: const BorderRadius.only(
    //                                   topLeft: Radius.circular(14),
    //                                   topRight: Radius.circular(6),
    //                                   bottomLeft: Radius.circular(6),
    //                                   bottomRight: Radius.circular(6)),
    //                               color: FrontendConfigs.kPrimaryColor),
    //                           child: Padding(
    //                             padding: const EdgeInsets.only(left: 4.0),
    //                             child: Container(
    //                               decoration: const BoxDecoration(
    //                                 color: Colors.white,
    //                                 borderRadius: BorderRadius.only(
    //                                     topLeft: Radius.circular(12),
    //                                     topRight: Radius.circular(6),
    //                                     bottomLeft: Radius.circular(6),
    //                                     bottomRight: Radius.circular(6)),
    //                               ),
    //                               child: Center(
    //                                   child: CustomText(
    //                                 text: 'Bulk Order',
    //                                 fontSize: 12,
    //                                 fontWeight: FontWeight.w500,
    //                               )),
    //                             ),
    //                           ),
    //                         )
    //                       else
    //                         SizedBox(
    //                           height: 26,
    //                         ),
    //                       ExtendedImage.network(
    //                         model.image.toString(),
    //                         height: 129,
    //                         width: 167,
    //                         fit: BoxFit.fill,
    //                         cache: true,
    //                         loadStateChanged: (ExtendedImageState state) {
    //                           switch (state.extendedImageLoadState) {
    //                             case LoadState.loading:
    //                               return Padding(
    //                                 padding: const EdgeInsets.symmetric(
    //                                     vertical: 27.0, horizontal: 10),
    //                                 child: Shimmer.fromColors(
    //                                   baseColor: Colors.grey.shade300,
    //                                   highlightColor: Colors.grey.shade100,
    //                                   child: Image.asset(
    //                                     "assets/images/karyana.png",
    //                                     fit: BoxFit.fill,
    //                                     color: Colors.grey,
    //                                   ),
    //                                 ),
    //                               );
    //                             case LoadState.failed:
    //                               return Padding(
    //                                 padding: const EdgeInsets.symmetric(
    //                                     vertical: 27.0, horizontal: 10),
    //                                 child: Image.asset(
    //                                   "assets/images/karyana.png",
    //                                   fit: BoxFit.fill,
    //                                   color: Colors.grey[350],
    //                                 ),
    //                               );
    //                             default:
    //                               return state.completedWidget;
    //                           }
    //                         },
    //                         borderRadius:
    //                             BorderRadius.all(Radius.circular(30.0)),
    //                         //cancelToken: cancellationToken,
    //                       ),
    //                       const SizedBox(
    //                         height: 3,
    //                       ),
    //                       Container(
    //                         height: 81,
    //                         width: 167,
    //                         decoration: BoxDecoration(
    //                           color: Colors.white,
    //                           borderRadius: BorderRadius.circular(12),
    //                         ),
    //                         child: Column(
    //                           crossAxisAlignment: CrossAxisAlignment.start,
    //                           children: [
    //                             const SizedBox(
    //                               height: 8,
    //                             ),
    //                             Row(
    //                               mainAxisAlignment:
    //                                   MainAxisAlignment.spaceBetween,
    //                               children: [
    //                                 Padding(
    //                                   padding:
    //                                       const EdgeInsets.only(left: 12.0),
    //                                   child: CustomText(
    //                                     text: model.englishName.toString(),
    //                                     fontWeight: FontWeight.w500,
    //                                   ),
    //                                 ),
    //                                 Padding(
    //                                   padding:
    //                                       const EdgeInsets.only(right: 12.0),
    //                                   child: CustomText(
    //                                     text: model.packagingDetails.toString(),
    //                                     fontWeight: FontWeight.w500,
    //                                     fontSize: 12,
    //                                     color: FrontendConfigs.kAuthTextColor,
    //                                   ),
    //                                 ),
    //                               ],
    //                             ),
    //                             Divider(
    //                               color: FrontendConfigs.kTextFieldColor,
    //                               thickness: 1,
    //                             ),
    //                             Padding(
    //                               padding: const EdgeInsets.symmetric(
    //                                   horizontal: 12.0),
    //                               child: Row(
    //                                 mainAxisAlignment:
    //                                     MainAxisAlignment.spaceBetween,
    //                                 children: [
    //                                   Column(
    //                                     crossAxisAlignment:
    //                                         CrossAxisAlignment.start,
    //                                     mainAxisAlignment:
    //                                         MainAxisAlignment.center,
    //                                     children: [
    //                                       if (model.isOnDiscount!)
    //                                         Column(
    //                                           crossAxisAlignment:
    //                                               CrossAxisAlignment.start,
    //                                           children: [
    //                                             CustomText(
    //                                               text:
    //                                                   "${getDiscountPrice(regularPrice: model.price!, discount: model.discountPrice!)} Rs",
    //                                               fontSize: 16,
    //                                               fontWeight: FontWeight.w600,
    //                                               color: FrontendConfigs
    //                                                   .kPrimaryColor,
    //                                             ),
    //                                             Text(
    //                                               "${model.price.toString()} Rs",
    //                                               style: TextStyle(
    //                                                   color: FrontendConfigs
    //                                                       .kAuthTextColor,
    //                                                   fontWeight:
    //                                                       FontWeight.w500,
    //                                                   fontSize: 12,
    //                                                   decoration: TextDecoration
    //                                                       .lineThrough),
    //                                             )
    //                                           ],
    //                                         )
    //                                       else
    //                                         CustomText(
    //                                           text:
    //                                               "${model.price.toString()} Rs",
    //                                           fontSize: 16,
    //                                           fontWeight: FontWeight.w600,
    //                                           color:
    //                                               FrontendConfigs.kPrimaryColor,
    //                                         ),
    //                                     ],
    //                                   ),
    //                                   Container(
    //                                       height: 30,
    //                                       width: 30,
    //                                       child: IconButton(
    //                                           onPressed: () {
    //                                             if (model.favoriteUser!
    //                                                 .contains(user
    //                                                     .getUserDetails()!
    //                                                     .docId
    //                                                     .toString())) {
    //                                               ProductServices()
    //                                                   .removeProductFromFavorite(
    //                                                       userID: user
    //                                                           .getUserDetails()!
    //                                                           .docId
    //                                                           .toString(),
    //                                                       productID: model.docID
    //                                                           .toString());
    //                                             } else {
    //                                               ProductServices()
    //                                                   .addProductToFavorite(
    //                                                       userID: user
    //                                                           .getUserDetails()!
    //                                                           .docId
    //                                                           .toString(),
    //                                                       productID: model.docID
    //                                                           .toString());
    //                                             }
    //                                           },
    //                                           icon: !model.favoriteUser!
    //                                                   .contains(user
    //                                                       .getUserDetails()!
    //                                                       .docId
    //                                                       .toString())
    //                                               ? Icon(
    //                                                   CupertinoIcons.heart,
    //                                                   color: FrontendConfigs
    //                                                       .kAuthTextColor,
    //                                                 )
    //                                               : Icon(
    //                                                   CupertinoIcons.heart_fill,
    //                                                   color: FrontendConfigs
    //                                                       .kPrimaryColor,
    //                                                 ))),
    //                                 ],
    //                               ),
    //                             ),
    //                           ],
    //                         ),
    //                       ),
    //                       const SizedBox(
    //                         height: 6,
    //                       ),
    //                       ElevatedButton(
    //                         style: ElevatedButton.styleFrom(
    //                             elevation: 0,
    //                             backgroundColor: Colors.black,
    //                             shape: RoundedRectangleBorder(
    //                               borderRadius: FrontendConfigs.kAppBorder,
    //                             )),
    //                         onPressed: () async {
    //                           if (_cartList.isNotEmpty) {
    //                             if (_cartList[0].quantity! == model.stock!) {
    //                               getFlushBar(context,
    //                                   title:
    //                                       "Sorry! We do not have enough stock");
    //                               return;
    //                             }
    //                             await CartServices().incrementProductQuantity(
    //                                 context,
    //                                 productID: _cartList[0].docID.toString(),
    //                                 updatedPrice: model.isOnDiscount!
    //                                     ? getDiscountPrice(
    //                                     regularPrice: model.price!,
    //                                     discount: model.discountPrice!)
    //                                     : model.price!,
    //                                 uid: user
    //                                     .getUserDetails()!
    //                                     .docId
    //                                     .toString());
    //                           } else {
    //                             await CartServices().addToCart(context,
    //                                 model: CartModel(
    //                                     quantity: 1,
    //                                     totalPrice: model.isOnDiscount!
    //                                         ? getDiscountPrice(
    //                                             regularPrice: model.price!,
    //                                             discount: model.discountPrice!)
    //                                         : model.price!,
    //                                     sortTime: DateTime.now()
    //                                         .millisecondsSinceEpoch,
    //                                     uid: user
    //                                         .getUserDetails()!
    //                                         .docId
    //                                         .toString(),
    //                                     productDetails: OrderedProductModel(
    //                                       productId: model.docID.toString(),
    //                                       catId: model.categoryId.toString(),
    //                                       images: model.image,
    //                                       price: model.isOnDiscount!
    //                                           ? getDiscountPrice(
    //                                                   regularPrice:
    //                                                       model.price!,
    //                                                   discount:
    //                                                       model.discountPrice!)
    //                                               .toString()
    //                                           : model.price!.toString(),
    //                                       productName:
    //                                           model.englishName.toString(),
    //                                       productDescription:
    //                                           model.packagingDetails.toString(),
    //                                       address: "",
    //                                     )),
    //                                 uid: user
    //                                     .getUserDetails()!
    //                                     .docId
    //                                     .toString());
    //                           }
    //                           Navigator.push(
    //                               context,
    //                               MaterialPageRoute(
    //                                   builder: (context) => const CartView()));
    //                         },
    //                         child: Row(
    //                           mainAxisAlignment: MainAxisAlignment.center,
    //                           children: [
    //                             Text(
    //                               TranslationHelper.getTranslatedText(
    //                                   "buy_now"),
    //                               style: TextStyle(
    //                                 color: Colors.white,
    //                                 fontWeight: FontWeight.w500,
    //                                 fontSize: 15,
    //                               ),
    //                             ),
    //                           ],
    //                         ),
    //                       ),
    //                     ],
    //                   ),
    //                 ),
    //               ),
    //             );
    //           });
    //     });
  }
}
