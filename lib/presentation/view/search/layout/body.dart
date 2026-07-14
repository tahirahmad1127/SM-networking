import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/configurations/translation_helper.dart';
import 'package:provider/provider.dart';

import '../../../../application/search_providers.dart';
import '../../../../configurations/frontend_configs.dart';
import '../../../../infrastructure/model/product.dart';

class SearchViewBody extends StatefulWidget {
  const SearchViewBody({super.key});

  @override
  State<SearchViewBody> createState() => _SearchViewBodyState();
}

class _SearchViewBodyState extends State<SearchViewBody> {
  final TextEditingController _searchController = TextEditingController();

  List<ProductModel> searchedProducts = [];

  bool isSearchingAllow = false;

  bool isSearched = false;

  void _searchData(String val) async {
    var search = Provider.of<SearchProviders>(context, listen: false);

    searchedProducts.clear();

    setState(() {});
    // for (var i in search.getProductList) {
    //   var lowerCaseString = i.englishName.toString().toLowerCase();
    //
    //   var defaultCase = i.englishName.toString();
    //   print(defaultCase);
    //   if (lowerCaseString.contains(val) || defaultCase.contains(val)) {
    //     isSearched = true;
    //     searchedProducts.add(i);
    //   } else {
    //     isSearched = true;
    //   }
    //
    //   setState(() {});
    // }
  }

  @override
  Widget build(BuildContext context) {
    var search = Provider.of<SearchProviders>(context);
    var user = Provider.of<UserProvider>(context);
    return SafeArea(
        child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(children: [
            Column(
              children: [
                const SizedBox(
                  height: 18,
                ),
                TextFormField(
                  keyboardType: TextInputType.text,
                  controller: _searchController,
                  onChanged: (val) {
                    if (val.isEmpty) {
                      searchedProducts.clear();

                      setState(() {});
                    } else {
                      _searchData(val);
                      setState(() {});
                    }
                  },
                  decoration: InputDecoration(
                      contentPadding: EdgeInsets.zero,
                      hintText: TranslationHelper.getTranslatedText('search'),
                      hintStyle: TextStyle(
                          color: FrontendConfigs.kAuthTextColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w500),
                      border: OutlineInputBorder(
                          borderRadius: FrontendConfigs.kAppBorder,
                          borderSide: BorderSide.none),
                      fillColor: FrontendConfigs.kTextFieldColor,
                      filled: true,
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: SvgPicture.asset("assets/icons/search.svg"),
                      )),
                ),
                const SizedBox(
                  height: 18,
                ),
              ],
            ),
          ]),
        ),
        // Expanded(
        //   child: StreamProvider.value(
        //     value: ProductServices()
        //         .streamLatestProducts(user.getUserDetails()!.cityID.toString()),
        //     initialData: [ProductModel()],
        //     builder: (context, child) {
        //       List<ProductModel> _list = context.watch<List<ProductModel>>();
        //       search.saveProductList(_list);
        //       return _list.isNotEmpty
        //           ? _list[0].docID == null
        //               ? Center(
        //                   child: SavedProductsLoader(),
        //                 )
        //               : searchedProducts.isEmpty
        //                   ? Center(
        //                       child: Column(
        //                         mainAxisAlignment: MainAxisAlignment.center,
        //                         children: [
        //                           Image.asset(
        //                             "assets/images/search.png",
        //                             height: 180,
        //                             width: 180,
        //                           ),
        //                           const SizedBox(
        //                             height: 18,
        //                           ),
        //                           Text(
        //                             TranslationHelper.getTranslatedText(
        //                                 "Search Product!"),
        //                             style: FrontendConfigs.kSubHeadingStyle,
        //                           ),
        //                         ],
        //                       ),
        //                     )
        //                   : Padding(
        //                       padding:
        //                           const EdgeInsets.symmetric(horizontal: 12.0),
        //                       child: GridView.builder(
        //                           shrinkWrap: true,
        //                           itemCount: searchedProducts.length,
        //                           physics: const BouncingScrollPhysics(),
        //                           gridDelegate:
        //                               const SliverGridDelegateWithMaxCrossAxisExtent(
        //                                   maxCrossAxisExtent: 320,
        //                                   childAspectRatio: 2 / 2,
        //                                   mainAxisExtent: 320,
        //                                   mainAxisSpacing: 15,
        //                                   crossAxisSpacing: 15),
        //                           itemBuilder: (context, i) {
        //                             return SearchCard(
        //                               model: searchedProducts[i],
        //                             );
        //                           }),
        //                     )
        //           : NoDataFoundView();
        //     },
        //   ),
        // ),
      ],
    ));
  }
}
