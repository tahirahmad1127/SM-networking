import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sm_networking/application/brand_bloc/brand_bloc.dart';
import 'package:sm_networking/application/product_bloc/product_bloc.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/infrastructure/model/brand.dart';
import 'package:sm_networking/presentation/elements/processing_widget.dart';
import 'package:sm_networking/presentation/elements/product_card.dart';
import 'package:sm_networking/presentation/elements/product_details_card.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../../application/user_provider.dart';
import '../../../../application/retailer_provider.dart';
import '../../../../infrastructure/model/category.dart';
import '../../../../infrastructure/model/product.dart';
import '../../../../injection_container.dart';

class CategoriesBody extends StatefulWidget {
  final CategoryModel model;
  final bool showCart;

  const CategoriesBody(
      {super.key, required this.model, required this.showCart});

  @override
  State<CategoriesBody> createState() => _CategoriesBodyState();
}

class _CategoriesBodyState extends State<CategoriesBody> {
  String? brandID;

  List<BrandModel> _brandList = [];
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  final List<ProductModel> _productList = [];

  bool isAllSelected = true;

  @override
  Widget build(BuildContext context) {
    var user = Provider.of<UserProvider>(context);

    // Session can be cleared out from under this screen mid-build (forced
    // logout on a 401) — the product/brand fetches below assume a non-null
    // user, so bail out to a harmless placeholder for that one frame
    // instead of crashing.
    if (user.getSalesUserDetails()?.user == null) {
      return const SizedBox.shrink();
    }

    log(widget.model.id.toString());
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<ProductBloc>(),
        ),
        BlocProvider(
          create: (context) => sl<BrandBloc>(),
        ),
      ],
      child: BlocBuilder<BrandBloc, BrandState>(
        builder: (context, state) {
          if (state is BrandInitial ||
              (state is BrandLoading && _brandList.isEmpty)) {
            BlocProvider.of<BrandBloc>(context)
                .add(GetBrandEvent(widget.model.id.toString()));
            return const Center(child: ProcessingWidget());
          } else if (state is BrandLoaded && _brandList.isEmpty) {
            // Only set the list if it's empty to avoid clearing on rebuild
            _brandList = state.model.data ?? [];
          }
          return BlocBuilder<ProductBloc, ProductState>(
            builder: (productContext, productState) {
              if (productState is ProductInitial && _productList.isEmpty) {
                BlocProvider.of<ProductBloc>(productContext).add(
                    GetProductEvent(
                        cityID: user
                            .getSalesUserDetails()!
                            .user!
                            .zone
                            .toString()
                            .trim(),
                        categoryID: widget.model.id.toString().trim(),
                        brandID: (brandID ?? "").trim(),
                        isRefresh: true));
                // return Center(child: const ProcessingWidget());
              } else if (productState is ProductLoaded) {
                _productList.addAll(productState.model.data!.where((a) {
                  return _productList.every((b) => a.id != b.id);
                }));
                if (productState.model.data!.isEmpty) {
                  _refreshController.loadNoData();
                } else {
                  _refreshController.loadComplete();
                }
              } else if (productState is ProductFailed &&
                  _productList.isEmpty) {
                return Center(
                  child: Text(productState.message.toString()),
                );
              } else if (productState is ProductFailed &&
                  _productList.isNotEmpty) {
                _refreshController.loadFailed();
              }
              log("Product List Length: ${_productList.length}");

              return Column(
                children: [
                  SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: SizedBox(
                      height: 30,
                      // color: Colors.blue,
                      child: ListView.builder(
                          itemCount: _brandList.length,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, i) {
                            return Row(
                              children: [
                                if (i == 0)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2.0),
                                    child: InkWell(
                                      onTap: () {
                                        brandID = null;
                                        isAllSelected = true;
                                        _productList.clear();
                                        setState(() {});
                                        BlocProvider.of<ProductBloc>(
                                                productContext)
                                            .add(GetProductEvent(
                                                cityID: user
                                                    .getSalesUserDetails()!
                                                    .user!
                                                    .zone
                                                    .toString(),
                                                brandID: brandID ?? "",
                                                categoryID:
                                                    widget.model.id.toString(),
                                                isRefresh: true));
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color:
                                                FrontendConfigs.kPrimaryColor,
                                            width: 1,
                                          ),
                                          color: isAllSelected
                                              ? FrontendConfigs.kPrimaryColor
                                              : FrontendConfigs.kPrimaryColor
                                                  .withOpacity(0.3),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12.0),
                                          child: Center(
                                            child: Text(
                                              "All",
                                              style: FrontendConfigs.kTitleStyle
                                                  .copyWith(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: isAllSelected
                                                          ? Colors.white
                                                          : Colors.black),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 2.0),
                                  child: InkWell(
                                    onTap: () {
                                      brandID = _brandList[i].id.toString();
                                      isAllSelected = false;
                                      _productList.clear();
                                      setState(() {});
                                      BlocProvider.of<ProductBloc>(
                                              productContext)
                                          .add(GetProductEvent(
                                              cityID: user
                                                  .getSalesUserDetails()!
                                                  .user!
                                                  .zone
                                                  .toString(),
                                              brandID: brandID ?? "",
                                              categoryID:
                                                  widget.model.id.toString(),
                                              isRefresh: true));
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: FrontendConfigs.kPrimaryColor,
                                          width: 1,
                                        ),
                                        color: brandID ==
                                                _brandList[i].id.toString()
                                            ? FrontendConfigs.kPrimaryColor
                                            : FrontendConfigs.kPrimaryColor
                                                .withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12.0),
                                        child: Center(
                                          child: Text(
                                            _brandList[i]
                                                .englishName
                                                .toString(),
                                            style: FrontendConfigs.kTitleStyle
                                                .copyWith(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: brandID ==
                                                            _brandList[i]
                                                                .id
                                                                .toString()
                                                        ? Colors.white
                                                        : Colors.black),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Expanded(
                    child: productState is ProductLoading &&
                            _productList.isEmpty
                        ? Center(
                            child: ProcessingWidget(),
                          )
                        : SmartRefresher(
                            enablePullDown: false,
                            enablePullUp: true,
                            controller: _refreshController,
                            onLoading: () {
                              BlocProvider.of<ProductBloc>(productContext).add(
                                  GetProductEvent(
                                      cityID: user
                                          .getSalesUserDetails()!
                                          .user!
                                          .zone
                                          .toString(),
                                      brandID: brandID ?? "",
                                      categoryID: widget.model.id.toString(),
                                      isRefresh: false));
                            },
                            header: const WaterDropHeader(),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: GridView.builder(
                                  shrinkWrap: true,
                                  itemCount: _productList.length,
                                  physics: const BouncingScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                          // maxCrossAxisExtent: 300,
                                          childAspectRatio: 3,
                                          mainAxisExtent:
                                              widget.showCart ? 312 : 255,
                                          mainAxisSpacing: 15,
                                          crossAxisSpacing: 15,
                                          crossAxisCount: 2),
                                  itemBuilder: (context, i) {
                                    if (widget.showCart) {
                                      return ProductCard(
                                          model: _productList[i],
                                          showCtnBox:
                                              Provider.of<RetailerProvider>(
                                                          context,
                                                          listen: false)
                                                      .getRetailer()
                                                      ?.customerType !=
                                                  'distributor');
                                    } else {
                                      return ProductDetailsCard(
                                          model: _productList[i]);
                                    }
                                  }),
                            ),
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
