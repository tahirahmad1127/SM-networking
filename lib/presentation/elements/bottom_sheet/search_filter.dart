import 'package:flutter/material.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/presentation/elements/app_button.dart';
import 'package:sm_networking/presentation/elements/category_card.dart';
import 'package:sm_networking/presentation/elements/custom_text.dart';


import '../../../utils/utils.dart';

Future<void> showSearchFilter(context) {
  return showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Search Filter",
                      style: FrontendConfigs.kTitleStyle,
                    ),
                    IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        }, icon: const Icon(Icons.close))
                  ],
                ),
              ),
              Divider(
                color: FrontendConfigs.kAuthTextColor,
                thickness: 0.2,
                height:0,
              ),
              const SizedBox(height:12,),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: CustomText(
                  text: "Choose Brands",
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              SizedBox(
                height: 100,
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: Utils.brandsList.length,
                    itemBuilder: (context, i) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: CategoryCard(
                            image: Utils.brandsList[i].image,
                            name: Utils.brandsList[i].name),
                      );
                    }),
              ),
              Divider(
                color: FrontendConfigs.kAuthTextColor,
                thickness: 0.2,
              ),

              const SizedBox(
                height: 18,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: CustomText(
                  text: "Size",
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(
                height: 14,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: SizedBox(
                  height: 50,
                  child: ListView.builder(
                      itemCount: Utils.sizeList.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, i) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 5.0),
                          child: Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: FrontendConfigs.kTextFieldColor,
                            ),
                            child: Center(
                                child: CustomText(
                              text: Utils.sizeList[i].toString(),
                            )),
                          ),
                        );
                      }),
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              Divider(
                color: FrontendConfigs.kAuthTextColor,
                thickness: 0.2,
              ),
              const SizedBox(
                height: 12,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: CustomText(
                  text: "Availability",
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(
                height: 14,
              ),
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                  ),
                  Container(

                    decoration: BoxDecoration(
                        borderRadius: FrontendConfigs.kAppBorder,
                        color:
                            FrontendConfigs.kPrimaryColor.withOpacity(0.2)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal:8.0,vertical:16),
                      child: CustomText(
                        text: 'Bulk Order',
                        color: FrontendConfigs.kPrimaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: FrontendConfigs.kAppBorder,
                        color: FrontendConfigs.kTextFieldColor),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal:8.0,vertical:16),
                      child: CustomText(
                        text: 'Single Item',
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 10,
              ),
             FrontendConfigs.appDivider,
              const SizedBox(
                height: 12,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppButton(
                      onPressed: () {},
                      btnLabel: "Clear",
                      width: MediaQuery.of(context).size.width / 2.25,
                      btnColor: const Color(0xff121212),
                      height:48,
                    ),
                    AppButton(
                      onPressed: () {},
                      btnLabel: "Apply Filters",
                      width: MediaQuery.of(context).size.width / 2.25,
                      height:48,
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 14,
              ),
            ],
          );
        });
      });
}
