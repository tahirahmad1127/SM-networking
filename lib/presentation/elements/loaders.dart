import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class HorizontalProductLoader extends StatelessWidget {
  const HorizontalProductLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Center(
          child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: ListView.builder(
                    itemCount: 4,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, i) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Container(
                          height: 250,
                          width: 190,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }),
              ))),
    );
  }
}

class HorizontalBannerLoader extends StatelessWidget {
  const HorizontalBannerLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
          child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 200,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey,
                ),
              ))),
    );
  }
}

class OrdersLoader extends StatelessWidget {
  const OrdersLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: ListView.builder(
                itemCount: 4,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15.0, vertical: 5),
                    child: Container(
                      height: 170,
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey,
                      ),
                    ),
                  );
                })));
  }
}

class NotificationLoader extends StatelessWidget {
  const NotificationLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: ListView.builder(
                itemCount: 4,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15.0, vertical: 5),
                    child: Container(
                      height: 80,
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey,
                      ),
                    ),
                  );
                })));
  }
}

class HorizontalCategoryLoader extends StatelessWidget {
  const HorizontalCategoryLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Center(
          child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: ListView.builder(
                  itemCount: 8,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, i) {
                    return Row(
                      children: [
                        if (i == 0)
                          SizedBox(
                            width: 18,
                          ),
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    );
                  }))),
    );
  }
}

class SavedProductsLoader extends StatelessWidget {
  const SavedProductsLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: GridView.builder(
              shrinkWrap: true,
              itemCount: 4,
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  mainAxisExtent: 280,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15),
              itemBuilder: (context, i) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey,
                  ),
                );
              })),
    );
  }
}
