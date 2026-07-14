import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/presentation/elements/custom_text.dart';
import 'package:shimmer/shimmer.dart';

class CategoryCard extends StatelessWidget {
  CategoryCard(
      {super.key,
      required this.image,
      required this.name,
      this.textColor,
      this.bgColor});
  final String image;
  final String name;
  Color? textColor;
  Color? bgColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
              border: Border.all(color: Color(0xffd2d2d5)),
              borderRadius: BorderRadius.all(Radius.circular(15.0)),
              color: bgColor ?? FrontendConfigs.kTextFieldColor),
          child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(20.0)),
                child: ExtendedImage.network(
                  image.toString(),
                  cacheHeight: 200,
                  cacheWidth: 200,
                  fit: BoxFit.fill,
                  cache: true,
                  loadStateChanged: (ExtendedImageState state) {
                    switch (state.extendedImageLoadState) {
                      case LoadState.loading:
                        return Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Image.asset(
                            "assets/images/karyana.png",
                            fit: BoxFit.fill,
                            color: Colors.grey,
                          ),
                        );
                      case LoadState.failed:
                        return Image.asset(
                          "assets/images/karyana.png",
                          fit: BoxFit.fill,
                          color: Colors.grey[350],
                        );
                      default:
                        return state.completedWidget;
                    }
                  },
                  borderRadius: BorderRadius.all(Radius.circular(30.0)),
                  //cancelToken: cancellationToken,
                ),
              )),
        ),
        const SizedBox(
          height: 5,
        ),
        SizedBox(
          width: 130,
          child: CustomText(
            text: name,
            color: textColor,
          ),
        )
      ],
    );
  }
}
